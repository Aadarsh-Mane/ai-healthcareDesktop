import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:glassmorphism/glassmorphism.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Profile",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, color: Colors.white),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade900, Colors.black])),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 30),
              SizedBox(
                height: 270,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const UserInfoCard(),
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 130,
                        width: 130,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black,
                            image: DecorationImage(
                              image: NetworkImage(
                                  'https://images.unsplash.com/photo-1639628735078-ed2f038a193e?q=80&w=1974&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'),
                            )),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: PrimaryButton()),
                  SizedBox(width: 10),
                  Expanded(child: SecondaryButton())
                ],
              ),
              const SizedBox(height: 30),
              // ListView.separated(
              //     shrinkWrap: true,
              //     physics: const NeverScrollableScrollPhysics(),
              //     itemBuilder: (ctx, i) {
              //       return MusicTile(
              //         onTap: () {},
              //         i: i,
              //       );
              //     },
              //     separatorBuilder: (ctx, i) =>
              //         const Divider(color: Colors.white),
              //     itemCount: 5)
            ],
          ),
        ),
      ),
    );
  }
}

class MusicTile extends StatelessWidget {
  final int i;
  final VoidCallback onTap;
  const MusicTile({
    Key? key,
    required this.i,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      dense: true,
      leading: i <= 9
          ? Text(
              '0i',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            )
          : Text(i.toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
      title: const Text("Mi Amor",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
      subtitle: const Text("Mr 6ix9ine 02 :43min",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          )),
      trailing:
          const SizedBox(height: 35, width: 35, child: CustomLikeButton()),
    );
  }
}

class CustomLikeButton extends StatelessWidget {
  const CustomLikeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return LikeButton(
      size: 30,
      circleSize: 30,
      circleColor: const CircleColor(start: Colors.teal, end: Colors.teal),
      bubblesColor: const BubblesColor(
        dotPrimaryColor: Colors.teal,
        dotSecondaryColor: Colors.teal,
      ),
      likeBuilder: (bool isLiked) {
        return isLiked
            ? const Icon(
                Icons.favorite,
                color: Colors.teal,
                size: 25,
              )
            : const Icon(
                Icons.favorite_border_outlined,
                color: Colors.white,
                size: 25,
              );
      },
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            fixedSize: const Size(double.maxFinite, 50)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline_rounded,
                size: 30, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Play",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ));
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withAlpha(45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            fixedSize: const Size(double.maxFinite, 50)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shuffle_on_outlined, size: 25, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Shuffle",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ));
  }
}

class UserInfoCard extends StatelessWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.maxFinite,
      height: 200,
      borderRadius: 10,
      blur: 17,
      border: 0,
      alignment: Alignment.center,
      borderGradient: LinearGradient(
          colors: [Colors.white.withAlpha(45), Colors.white.withAlpha(45)]),
      linearGradient: LinearGradient(
          colors: [Colors.white.withAlpha(45), Colors.white.withAlpha(45)]),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Tattle Tales",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Divider(color: Colors.white),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      "13",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    Text("Songs",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ))
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "113M",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    Text("Followers",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ))
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "2020",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    Text("Likes",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ))
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
