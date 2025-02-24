import 'package:doctordesktop/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class ModeView extends StatefulWidget {
  @override
  State<ModeView> createState() => _ModeViewState();
}

class _ModeViewState extends State<ModeView> {
  bool isAcON = true;
  double _currentSliderValue = 20;
  double _temperatureValue = 50;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   elevation: 0,
      //   backgroundColor: Colors.transparent,
      //   leading: IconButton(child: const CustomIcons(icon: Icons.menu )),
      //   centerTitle: true,
      //   title: Text('LATEST PATIENT INFO',
      //       style: const TextStyle(
      //           fontSize: 18,
      //           fontWeight: FontWeight.bold,
      //           color: Colors.deepOrangeAccent)),
      //   actions: const [CustomIcons(icon: Icons.notifications)],
      // ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.back_hand, color: Colors.deepOrangeAccent),
          onPressed: () {
            Navigator.pop(context); // This will pop the current screen
          },
        ),
        centerTitle: true,
        title: Text(
          'LATEST PATIENT INFO',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrangeAccent,
          ),
        ),
        actions: const [
          CustomIcons(icon: Icons.notifications),
        ],
      ),
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bb1.png',
            fit: BoxFit.cover,
            opacity: AlwaysStoppedAnimation(0.3),
          ),
        ),
        Container(
            height: double.maxFinite,
            width: double.maxFinite,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SafeArea(
                child: SingleChildScrollView(
              child: Column(children: [
                const SizedBox(height: 20),
                SleekCircularSlider(
                  appearance: CircularSliderAppearance(
                      size: 190,
                      infoProperties: InfoProperties(
                          topLabelStyle: const TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          topLabelText: 'Room Temperature',
                          mainLabelStyle: const TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 30,
                              fontWeight: FontWeight.w800),
                          modifier: (double value) {
                            final temperature = value.toInt();
                            return temperature.toString();
                          }),
                      customColors: CustomSliderColors(
                          dotColor: Color(0xFFFFA726),
                          progressBarColor: Colors.deepOrange,
                          trackColors: [
                            Color(0xFF1E1E2C),
                            Color(0xFF282C34)
                            // CustomColor.kBackground2,
                            // CustomColor.kBackground1
                          ]),
                      customWidths: CustomSliderWidths(
                        progressBarWidth: 10,
                        trackWidth: 40,
                      )),
                  min: 16,
                  max: 54,
                  initialValue: _temperatureValue,
                  onChange: (value) {
                    setState(() {
                      _temperatureValue = value;
                    });
                  },
                ),
                const SizedBox(height: 40),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Temperature',
                          style:
                              TextStyle(fontSize: 12, color: Color(0xFF001F3F)),
                        ),
                        Text(
                          '28°C',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Humidity',
                          style:
                              TextStyle(fontSize: 12, color: Colors.deepOrange),
                        ),
                        Text(
                          '54%',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepOrange),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 80,
                  width: double.maxFinite,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      // color: Colors.amberAccent,
                      border: Border.all(
                          color: Colors.lightBlueAccent.withOpacity(0.1))),
                  child: Row(
                    children: [
                      const Icon(Icons.snowing, color: Colors.white),
                      const SizedBox(width: 10),
                      const Text(
                        "Other Latest Details",
                        style: TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Switch(
                        activeColor: Colors.lightGreenAccent,
                        value: isAcON,
                        onChanged: (value) {
                          setState(() {
                            isAcON = value;
                          });
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(
                        child: TemperatureCard(
                      heading: 'Temperature',
                      temperature: '28°C',
                      color: Colors.deepOrange,
                    )),
                    SizedBox(width: 10),
                    Expanded(
                        child: TemperatureCard(
                      heading: 'BP',
                      temperature: '18°C',
                      color: Colors.lightBlueAccent,
                    )),
                    SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(
                        child: TemperatureCard(
                      heading: 'Symptoms',
                      temperature: 'cold fever',
                      color: Colors.deepOrange,
                    )),
                    SizedBox(width: 10),
                    Expanded(
                        child: TemperatureCard(
                      heading: 'Diagnosis',
                      temperature: 'Malaria',
                      color: Colors.lightBlueAccent,
                    )),
                    SizedBox(width: 10),
                    Expanded(
                        child: TemperatureCard(
                      heading: 'BSL',
                      temperature: '28°C',
                      color: Colors.lightGreenAccent,
                    )),
                    SizedBox(width: 10),
                  ],
                )
              ]),
            ))),
      ]),
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class CustomIcons extends StatelessWidget {
  final IconData icon;

  const CustomIcons({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          shape: BoxShape.circle, border: Border.all(color: Colors.black)),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white),
    );
  }
}

class TemperatureCard extends StatelessWidget {
  final String heading;
  final String temperature;
  final Color color;
  const TemperatureCard(
      {super.key,
      required this.heading,
      required this.temperature,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
          color: Color(0xFF001F3F), borderRadius: BorderRadius.circular(10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(heading,
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
              const SizedBox(width: 5),
              Container(
                height: 5,
                width: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
            ],
          ),
          Text(
            temperature,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 30),
          ),
        ],
      ),
    );
  }
}
