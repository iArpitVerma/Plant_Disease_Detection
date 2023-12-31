import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_disease_detector/constants/constants.dart';
import 'package:plant_disease_detector/services/classify.dart';
import 'package:plant_disease_detector/services/disease_provider.dart';
import 'package:plant_disease_detector/services/hive_database.dart';
import 'package:plant_disease_detector/src/home_page/components/greeting.dart';
import 'package:plant_disease_detector/src/home_page/components/history.dart';
import 'package:plant_disease_detector/src/home_page/components/instructions.dart';
import 'package:plant_disease_detector/src/home_page/components/titlesection.dart';
import 'package:plant_disease_detector/src/home_page/models/disease_model.dart';
import 'package:plant_disease_detector/src/suggestions_page/not_sure_page.dart';
import 'package:plant_disease_detector/src/suggestions_page/suggestions.dart';
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void dispose() {
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get disease from provider
    final _diseaseService = Provider.of<DiseaseService>(context);

    // Hive service
    HiveService _hiveService = HiveService();

    // Data
    Size size = MediaQuery.of(context).size;
    final Classifier classifier = Classifier();
    late Disease _disease;

    return SafeArea(
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SpeedDial(
          child: const FaIcon(
            FontAwesomeIcons.cameraRetro,
            color: kWhite,
          ),
          backgroundColor: kMain,
          onOpen: () async {
            late double _confidence;
            await classifier.getDisease(ImageSource.gallery).then((value) {
              _disease = Disease(
                  name: value![0]["label"] ?? "Not sure",
                  imagePath: classifier.imageFile.path);
              _confidence = value[0]['confidence'];
            });
            // Check confidence
            if (_confidence > 0.8) {
              // Set disease for Disease Service
              _diseaseService.setDiseaseValue(_disease);

              // Save disease
              _hiveService.addDisease(_disease);
              Navigator.restorablePushNamed(
                context,
                Suggestions.routeName,
              );
            } else {
              // Display unsure message
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return NotSurePage();
              }));
            }
          },
        ),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/bg.jpg'), fit: BoxFit.cover),
            ),
            child: CustomScrollView(
              slivers: [
                GreetingSection(size.height * 0.16),
                TitleSection('Instructions', size.height * 0.066),
                InstructionsSection(size),
                TitleSection('Your History', size.height * 0.066),
                HistorySection(size, context, _diseaseService)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
