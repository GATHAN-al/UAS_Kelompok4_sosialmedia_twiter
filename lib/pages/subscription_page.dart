import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Define the model for Subscription Plans
class SubscriptionPlan {
  final String name;
  final String description;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> features;

  SubscriptionPlan({
    required this.name,
    required this.description,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
  });
}

// Sample list of subscription plans
final List<SubscriptionPlan> plans = [
  SubscriptionPlan(
    name: 'Basic',
    description: 'Enhanced Experience',
    monthlyPrice: 31000.00,
    annualPrice: 325000.00,
    features: [
      'Gran 4 AI Assistant',
      'Reply boost',
      'Radar',
      'Edit post',
      'Longer posts',
    ],
  ),
  SubscriptionPlan(
    name: 'Premium',
    description: 'Premium Experience',
    monthlyPrice: 45000.00,
    annualPrice: 490000.00,
    features: [
      'All Basic Features',
      'Priority support',
      'No ads',
      'Exclusive articles',
    ],
  ),
  SubscriptionPlan(
    name: 'Ultra',
    description: 'Ultimate Experience',
    monthlyPrice: 70000.00,
    annualPrice: 770000.00,
    features: [
      'All Premium Features',
      'VIP support',
      'Video downloads',
      'Premium content',
    ],
  ),
];

class SubscriptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('S U B S C R I B E'),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Card(
            color: Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    plan.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Starting at Rp ${plan.monthlyPrice.toStringAsFixed(2)}/month',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ...plan.features.map(
                    (feature) => ListTile(
                      leading: Icon(Icons.check, color: Colors.green),
                      title: Text(
                        feature,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showPlanDetails(context, plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Subscribe & pay'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Function to show plan details with user agreement
  void _showPlanDetails(BuildContext context, SubscriptionPlan plan) {
    bool isAgreed = false; // Track checkbox state

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Monthly Plan: Rp ${plan.monthlyPrice.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                    Text(
                      'Annual Plan: Rp ${plan.annualPrice.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 18),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Features',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...plan.features.map((feature) => ListTile(
                          leading: Icon(Icons.check, color: Colors.green),
                          title: Text(
                            feature,
                            style: TextStyle(color: Colors.white),
                          ),
                        )),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: isAgreed,
                          onChanged: (value) {
                            setState(() {
                              isAgreed = value ?? false;
                            });
                          },
                          checkColor: Colors.white,
                          activeColor: Colors.blueAccent,
                        ),
                        Expanded(
                          child: Text(
                            'I agree to the Terms & Conditions',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    // Explanation text below the user agreement
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                      child: Text(
                        'By Subscribing, you agree to our Purchaser Terms of Service. Subscription auto-renew until cancelled. Cancel atleast 24 hours before renewal to avoid additional charges.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isAgreed
                            ? () {
                                _subscribeUser(context, plan); // Save subscription to Firestore
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Subscribe & pay', textAlign: TextAlign.center),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to subscribe user and save their plan to Firestore
  Future<void> _subscribeUser(BuildContext context, SubscriptionPlan plan) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Check if the user is already subscribed
    final subscriptionRef = FirebaseFirestore.instance.collection('subscriptions').doc(currentUserId);
    final subscriptionDoc = await subscriptionRef.get();

    if (subscriptionDoc.exists) {
      // User already subscribed, show pop-up message
      _showAlreadySubscribedMessage(context);
    } else {
      // Save subscription to Firestore
      await subscriptionRef.set({
        'planName': plan.name,
        'monthlyPrice': plan.monthlyPrice,
        'annualPrice': plan.annualPrice,
        'features': plan.features,
        'subscribedAt': FieldValue.serverTimestamp(),
      });

      // Show confirmation message
      _showThankYouMessage(context);
    }
  }

  // Function to show "You already subscribed" message
  void _showAlreadySubscribedMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            'You already subscribed!',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Optionally navigate back to a different page or close
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('OK', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  // Function to show thank you message after subscribing
  void _showThankYouMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(
            'Thank you for subscribing!',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally navigate to another page
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('OK', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }
}

// Entry point for the app
void main() {
  runApp(MaterialApp(
    home: SubscriptionScreen(),
  ));
}
