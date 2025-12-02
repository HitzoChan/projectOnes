import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, FirestoreProvider>(
      builder: (context, authProvider, firestoreProvider, child) {
        return FutureBuilder(
          future: authProvider.currentUser != null
              ? firestoreProvider.getUser(authProvider.currentUser!.uid)
              : null,
          builder: (context, snapshot) {
            String? profileImageUrl = imageUrl;
            
            // Use image from Firestore if available
            if (snapshot.hasData && snapshot.data?.profileImageUrl != null) {
              profileImageUrl = snapshot.data!.profileImageUrl;
            }

            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundImage:
                    profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: profileImageUrl == null || profileImageUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: radius * 0.6,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
