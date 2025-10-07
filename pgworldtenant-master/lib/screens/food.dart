import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../utils/api.dart';
import '../utils/config.dart';
import '../utils/models.dart';
import '../utils/utils.dart';
import './menu.dart';
import './mealHistory.dart';

class FoodActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return FoodActivityState();
  }
}

class FoodActivityState extends State<FoodActivity> {
  User? currentUser;
  bool loading = true;
  String mealPlan = "Not Selected";
  List<String> dietaryPreferences = [];
  String foodAllergies = "";

  // Meal plan options
  final List<MealPlanOption> mealPlans = [
    MealPlanOption(
      name: "Full Board",
      meals: ["Breakfast", "Lunch", "Dinner"],
      price: 3000,
      icon: Icons.restaurant_menu,
      color: Colors.green,
    ),
    MealPlanOption(
      name: "Two Meals",
      meals: ["Breakfast", "Dinner"],
      price: 2000,
      icon: Icons.free_breakfast,
      color: Colors.orange,
    ),
    MealPlanOption(
      name: "Breakfast Only",
      meals: ["Breakfast"],
      price: 1000,
      icon: Icons.breakfast_dining,
      color: Colors.blue,
    ),
    MealPlanOption(
      name: "No Meal Plan",
      meals: [],
      price: 0,
      icon: Icons.no_meals,
      color: Colors.grey,
    ),
  ];

  // Dietary preferences
  final List<String> dietaryOptions = [
    "Vegetarian",
    "Non-Vegetarian",
    "Vegan",
    "Jain Food",
    "No Onion/Garlic",
    "Gluten-Free",
    "Lactose-Free",
  ];

  @override
  void initState() {
    super.initState();
    loadUserFoodPreferences();
  }

  void loadUserFoodPreferences() {
    checkInternet().then((internet) {
      if (!internet) {
        oneButtonDialog(context, "No Internet connection", "", true);
        setState(() {
          loading = false;
        });
      } else {
        Map<String, String> filter = {
          'id': userID,
          'hostel_id': hostelID,
          'status': '1'
        };

        Future<Users> data = getUsers(filter);
        data.then((response) {
          if (response.users.length > 0) {
            setState(() {
              currentUser = response.users[0];
              _parseFoodPreferences();
              loading = false;
            });
          } else {
            setState(() {
              loading = false;
            });
          }
        });
      }
    });
  }

  void _parseFoodPreferences() {
    // Parse food preferences from user.food field
    // Format: "plan:Full Board;diet:Vegetarian,Vegan;allergies:Peanuts"
    if (currentUser?.food != null && currentUser!.food.isNotEmpty) {
      List<String> parts = currentUser!.food.split(';');
      for (String part in parts) {
        if (part.contains(':')) {
          List<String> keyValue = part.split(':');
          String key = keyValue[0].trim();
          String value = keyValue.length > 1 ? keyValue[1].trim() : '';

          if (key == 'plan') {
            mealPlan = value.isNotEmpty ? value : "Not Selected";
          } else if (key == 'diet') {
            dietaryPreferences = value.isNotEmpty ? value.split(',') : [];
          } else if (key == 'allergies') {
            foodAllergies = value;
          }
        }
      }
    }
  }

  String _buildFoodString() {
    String planPart = "plan:$mealPlan";
    String dietPart = "diet:${dietaryPreferences.join(',')}";
    String allergyPart = "allergies:$foodAllergies";
    return "$planPart;$dietPart;$allergyPart";
  }

  Future<void> _saveFoodPreferences() async {
    setState(() {
      loading = true;
    });

    Map<String, String> updateData = {
      'food': _buildFoodString(),
    };

    Map<String, String> query = {
      'id': userID,
      'hostel_id': hostelID,
    };

    bool success = await update(API.USER, updateData, query);

    setState(() {
      loading = false;
    });

    if (success) {
      oneButtonDialog(
          context, "Success", "Food preferences updated successfully", true);
    } else {
      oneButtonDialog(context, "Error", "Failed to update preferences", true);
    }
  }

  void _showMealPlanDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Meal Plan"),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: mealPlans.length,
              itemBuilder: (context, index) {
                MealPlanOption plan = mealPlans[index];
                bool isSelected = mealPlan == plan.name;
                return Card(
                  color:
                      isSelected ? plan.color.withOpacity(0.1) : Colors.white,
                  child: ListTile(
                    leading: Icon(plan.icon, color: plan.color, size: 32),
                    title: Text(
                      plan.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.meals.join(", ")),
                        SizedBox(height: 4),
                        Text(
                          "₹${plan.price}/month",
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: plan.color)
                        : null,
                    onTap: () {
                      setState(() {
                        mealPlan = plan.name;
                      });
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showDietaryPreferencesDialog() {
    List<String> tempPreferences = List.from(dietaryPreferences);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Dietary Preferences"),
              content: Container(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: dietaryOptions.length,
                  itemBuilder: (context, index) {
                    String option = dietaryOptions[index];
                    bool isSelected = tempPreferences.contains(option);
                    return CheckboxListTile(
                      title: Text(option),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempPreferences.add(option);
                          } else {
                            tempPreferences.remove(option);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      dietaryPreferences = tempPreferences;
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAllergiesDialog() {
    TextEditingController allergiesController =
        TextEditingController(text: foodAllergies);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Food Allergies"),
          content: TextField(
            controller: allergiesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter any food allergies (e.g., Peanuts, Shellfish)",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  foodAllergies = allergiesController.text.trim();
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MenuActivity()),
    );
  }

  void _navigateToMealHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MealHistoryActivity()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        title: Text("Food Management", style: TextStyle(color: Colors.black)),
        elevation: 4.0,
      ),
      body: ModalProgressHUD(
        child: loading
            ? Container()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[400]!, Colors.orange[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.restaurant, size: 50, color: Colors.white),
                          SizedBox(height: 12),
                          Text(
                            "Meal Preferences",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Manage your food preferences and meal plans",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Current Meal Plan
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Meal Plan",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                              Divider(),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mealPlan,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (mealPlan != "Not Selected" &&
                                            mealPlan != "No Meal Plan")
                                          Text(
                                            _getMealPlanPrice(mealPlan),
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _showMealPlanDialog,
                                    child: Text("Change"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Dietary Preferences
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.eco, color: Colors.green[700]),
                          ),
                          title: Text(
                            "Dietary Preferences",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            dietaryPreferences.isEmpty
                                ? "Not set"
                                : dietaryPreferences.join(", "),
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showDietaryPreferencesDialog,
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Food Allergies
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.warning_amber_rounded,
                                color: Colors.red[700]),
                          ),
                          title: Text(
                            "Food Allergies",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            foodAllergies.isEmpty ? "Not set" : foodAllergies,
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _showAllergiesDialog,
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Save Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveFoodPreferences,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Save Preferences",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Quick Actions
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.menu_book,
                                    color: Colors.blue[700]),
                              ),
                              title: Text("View Menu",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text("Check today's and weekly menu"),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: _navigateToMenu,
                            ),
                            Divider(height: 1),
                            ListTile(
                              leading: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.history,
                                    color: Colors.purple[700]),
                              ),
                              title: Text("Meal History",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              subtitle:
                                  Text("View your meal consumption history"),
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: _navigateToMealHistory,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32),
                  ],
                ),
              ),
        inAsyncCall: loading,
      ),
    );
  }

  String _getMealPlanPrice(String planName) {
    MealPlanOption? plan = mealPlans.firstWhere(
      (p) => p.name == planName,
      orElse: () => mealPlans.last,
    );
    return plan.price > 0 ? "₹${plan.price}/month" : "Free";
  }
}

// Meal Plan Model
class MealPlanOption {
  final String name;
  final List<String> meals;
  final int price;
  final IconData icon;
  final Color color;

  MealPlanOption({
    required this.name,
    required this.meals,
    required this.price,
    required this.icon,
    required this.color,
  });
}
