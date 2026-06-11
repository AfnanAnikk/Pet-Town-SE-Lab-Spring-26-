import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pet_town/main.dart' as app;
import 'package:pet_town/widgets/rolling_text_button.dart';
import 'package:pet_town/widgets/primary_button.dart';
import 'package:pet_town/widgets/custom_text_field.dart';
import 'package:pet_town/pages/adoption/rehome_page.dart';
import 'package:pet_town/pages/vet/pet_health_ai_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Helper to find TextFormField by hint text (finds the inner TextField)
  Finder findFieldByHint(String hint) {
    return find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == hint);
  }

  // Helper to find TextField by hint text
  Finder findTextFieldByHint(String hint) {
    return find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == hint);
  }

  // Helper to wait for a widget to appear in the tree
  Future<void> waitForWidget(WidgetTester tester, Finder finder, {int maxTries = 50}) async {
    for (int i = 0; i < maxTries; i++) {
      if (finder.evaluate().isNotEmpty) {
        await tester.pump(); // Pump one final frame
        return;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget); // Fail test if widget not found
  }

  // Helper to find BottomNavigationBar and click a tab index
  Future<void> tapBottomNavBarTab(WidgetTester tester, int index) async {
    final navBarFinder = find.byType(BottomNavigationBar);
    expect(navBarFinder, findsOneWidget);
    final BottomNavigationBar navBar = tester.widget(navBarFinder);
    navBar.onTap!(index);
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets("PetTown End-to-End User Flow Integration Test", (WidgetTester tester) async {
    // Start App
    app.main();
    await tester.pump(const Duration(seconds: 2));

    // ─── 1. Landing Page Onboarding ───
    final landingButton = find.byType(RollingTextButton);
    await waitForWidget(tester, landingButton);
    await tester.tap(landingButton);
    await tester.pump(const Duration(seconds: 2));

    // ─── 2. Signup Flow ───
    final signUpMainButton = find.widgetWithText(PrimaryButton, 'Sign Up');
    await waitForWidget(tester, signUpMainButton);
    await tester.tap(signUpMainButton);
    await tester.pump(const Duration(seconds: 2));

    // Enter registration details
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final testEmail = 'test_user_$uniqueId@example.com';
    final testUsername = 'user_$uniqueId';
    final testPassword = 'Password123';

    final emailField = findFieldByHint('user@gmail.com');
    await waitForWidget(tester, emailField);
    await tester.enterText(emailField, testEmail);
    await tester.enterText(findFieldByHint('Afnainna'), testUsername);

    // Find password fields by matching hintText.
    final passwordFields = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == '••••••••••');
    await tester.enterText(passwordFields.at(0), testPassword);
    await tester.enterText(passwordFields.at(1), testPassword);

    // Agree to terms checkbox
    final checkbox = find.byType(Checkbox);
    await tester.tap(checkbox);
    await tester.pump(const Duration(milliseconds: 500));

    // Tap register button
    final registerBtn = find.widgetWithText(PrimaryButton, 'Sign Up');
    await tester.tap(registerBtn);
    await tester.pump(const Duration(seconds: 4));

    // ─── 3. Login Flow ───
    // Enter credentials on LoginPage
    final loginEmailField = findFieldByHint('demo@gmail.com');
    await waitForWidget(tester, loginEmailField);
    await tester.enterText(loginEmailField, testEmail);

    final loginPasswordFields = find.byWidgetPredicate((widget) =>
        widget is TextField &&
        widget.decoration?.hintText == '••••••••••');
    await tester.enterText(loginPasswordFields, testPassword);

    // Tap Log In button
    final loginBtn = find.widgetWithText(PrimaryButton, 'Log in');
    await tester.tap(loginBtn);
    await tester.pump(const Duration(seconds: 4));

    // We should be on HomePage now! Wait for home content
    await waitForWidget(tester, find.text('Features'));

    // ─── 4. Navigation between major tabs ───
    // Tab index 1: Search
    await tapBottomNavBarTab(tester, 1);
    await waitForWidget(tester, find.text('Search'));

    // Tab index 3: Notifications
    await tapBottomNavBarTab(tester, 3);
    await waitForWidget(tester, find.text('Notifications'));

    // Tab index 4: Profile
    await tapBottomNavBarTab(tester, 4);
    await waitForWidget(tester, find.byTooltip('Booking & Order History'));

    // ─── 5. AI Pet Health Assistant Workflow ───
    // Go to Features bottom sheet
    await tapBottomNavBarTab(tester, 2);

    // Tap "Pet Vet"
    final petVetBtn = find.byTooltip('Pet Vet');
    await waitForWidget(tester, petVetBtn);
    await tester.tap(petVetBtn);
    await tester.pump(const Duration(seconds: 2));

    // Tap AI Pet Health Checker Banner
    final aiBanner = find.text('AI Pet Health Checker');
    await waitForWidget(tester, aiBanner);
    await tester.tap(aiBanner);
    await tester.pump(const Duration(seconds: 2));

    // We are on Step 1: Species & Vitals
    // Select Cat chip
    final catCard = find.text('Cat');
    if (catCard.evaluate().isNotEmpty) {
      await tester.tap(catCard);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Enter Vitals
    final tempField = find.widgetWithText(TextField, 'Temperature');
    final hrField = find.widgetWithText(TextField, 'Heart Rate');
    await tester.enterText(tempField, '39.2');
    await tester.enterText(hrField, '130');
    await tester.pump(const Duration(milliseconds: 500));

    // Tap "Next"
    final nextBtn1 = find.text('Next: Select Symptoms →');
    await tester.tap(nextBtn1);
    await tester.pump(const Duration(seconds: 1));

    // We are on Step 2: Symptom Picker
    // Select symptoms: Fever, Lethargy
    final feverChip = find.text('Fever');
    final lethargyChip = find.text('Lethargy');
    await waitForWidget(tester, feverChip);
    await tester.tap(feverChip);
    await tester.tap(lethargyChip);
    await tester.pump(const Duration(milliseconds: 500));

    // Tap "Analyze Now"
    final analyzeBtn = find.text('🔍 Analyze Now');
    await tester.tap(analyzeBtn);
    
    // Wait for analysis results page (it has ExpansionTile widgets)
    await waitForWidget(tester, find.byType(ExpansionTile), maxTries: 80);

    // Tap back to exit AI tool
    final backBtn = find.byType(IconButton).first;
    await tester.tap(backBtn);
    await tester.pump(const Duration(seconds: 2));

    // ─── 6. Vet Service & Appointment Booking Flow ───
    // Now back on VetListPage
    // Find first VetCard and tap "Consult Now"
    final consultBtn = find.text('Consult Now').first;
    await waitForWidget(tester, consultBtn);
    await tester.tap(consultBtn);
    await tester.pump(const Duration(seconds: 2));

    // Tap Book Appointment
    final bookApptBtn = find.text('Book Appointment');
    await waitForWidget(tester, bookApptBtn);
    await tester.tap(bookApptBtn);
    await tester.pump(const Duration(seconds: 2));

    // On VetBookingPage:
    // Select date and time chip (tap the first available date)
    final dateChips = find.byWidgetPredicate((w) => w is GestureDetector && w.child is Container);
    if (dateChips.evaluate().isNotEmpty) {
      await tester.tap(dateChips.first);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Tap Pet field to open Pet Details Sheet
    final petField = find.text('Pet');
    await tester.tap(petField);
    await tester.pump(const Duration(seconds: 2));

    // Fill Pet Details Sheet
    await tester.enterText(findTextFieldByHint('Enter pet name'), 'Milo');
    await tester.enterText(findTextFieldByHint('Breed'), 'Persian');
    await tester.enterText(findTextFieldByHint('Sex'), 'Male');
    await tester.enterText(findTextFieldByHint('Age (Years)'), '2');
    
    // Tap Apply
    final applyPetBtn = find.widgetWithText(ElevatedButton, 'Apply');
    await tester.tap(applyPetBtn);
    await tester.pump(const Duration(seconds: 2));

    // Tap Concern field to open Concern Sheet
    final concernField = find.text('Concern');
    await tester.tap(concernField);
    await tester.pump(const Duration(seconds: 2));

    // Tap a concern card (e.g. Skin) and click Apply
    final concernCard = find.text('Skin');
    await tester.tap(concernCard);
    await tester.pump(const Duration(milliseconds: 500));
    final applyConcernBtn = find.widgetWithText(ElevatedButton, 'Apply');
    await tester.tap(applyConcernBtn);
    await tester.pump(const Duration(seconds: 2));

    // Tap Reason field to open Reason Sheet
    final reasonField = find.text('Reason for visit');
    await tester.tap(reasonField);
    await tester.pump(const Duration(seconds: 2));

    // Enter reason and tap Save
    await tester.enterText(findTextFieldByHint('Briefly describe your reason for visit...'), 'Continuous scratching and dry skin patches.');
    final saveReasonBtn = find.widgetWithText(ElevatedButton, 'Save');
    await tester.tap(saveReasonBtn);
    await tester.pump(const Duration(seconds: 2));

    // Tap Payment Method field
    final paymentField = find.text('Tap to add');
    await tester.tap(paymentField);
    await tester.pump(const Duration(seconds: 2));

    // Select "On hand" and click Apply
    final paymentCard = find.text('On hand');
    await tester.tap(paymentCard);
    await tester.pump(const Duration(milliseconds: 500));
    final applyPaymentBtn = find.widgetWithText(ElevatedButton, 'Apply');
    await tester.tap(applyPaymentBtn);
    await tester.pump(const Duration(seconds: 2));

    // Confirm booking
    final confirmBookingBtn = find.widgetWithText(ElevatedButton, 'CONFIRM');
    await tester.tap(confirmBookingBtn);
    
    // Wait for VetBookingSuccessPage to open (contains text 'Success')
    await waitForWidget(tester, find.text('Success'), maxTries: 80);
    
    // Go back to main vet list page
    final successBack = find.byType(IconButton);
    if (successBack.evaluate().isNotEmpty) {
      await tester.tap(successBack.first);
      await tester.pump(const Duration(seconds: 2));
    }

    // ─── 7. Add Pet / Rehome Flow ───
    // Navigate to Features sheet -> Adoption
    await tapBottomNavBarTab(tester, 2);
    final adoptionFeatureBtn = find.byTooltip('Adoption');
    await waitForWidget(tester, adoptionFeatureBtn);
    await tester.tap(adoptionFeatureBtn);
    await tester.pump(const Duration(seconds: 2));

    // Tap on Re-Home Tab (tab index 1)
    final rehomeTab = find.text('Re-Home');
    await waitForWidget(tester, rehomeTab);
    await tester.tap(rehomeTab);
    await tester.pump(const Duration(seconds: 2));

    // Enter pet information details into the RehomePage Form
    await tester.enterText(findFieldByHint('Write your pet name here'), 'Rocky');
    await tester.enterText(findFieldByHint('Write your pet age here'), '2 Years');
    await tester.enterText(findFieldByHint('Write your pet breed here'), 'Golden Retriever');
    await tester.enterText(findFieldByHint('Write your pet traits here'), 'Playful, friendly, loves children');
    await tester.enterText(findFieldByHint('Write your pet gender here'), 'Male');
    await tester.enterText(findFieldByHint('Write your pet food habit here'), 'Dry kibble twice a day');
    await tester.enterText(findFieldByHint('Write your name here'), 'Test Owner');
    await tester.enterText(findFieldByHint('Write your contact number here'), '01712345678');
    await tester.enterText(findFieldByHint('Write something about your pet here'), 'Rocky is fully vaccinated and looking for a loving home.');

    // Inject mock image file inside state of RehomePage to bypass native file picker
    final rehomeStateFinder = find.byType(RehomePage);
    await waitForWidget(tester, rehomeStateFinder);
    final rehomeState = tester.state<RehomePageState>(rehomeStateFinder);

    final tempDir = await getTemporaryDirectory();
    final dummyImgFile = File('${tempDir.path}/test_image.png');
    // Write 1x1 valid transparent PNG pixel bytes to bypass Cloudinary/backend verification checks
    await dummyImgFile.writeAsBytes([
      137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
      0, 0, 0, 11, 73, 68, 65, 84, 120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 73, 175, 167, 104, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
    ]);

    rehomeState.setState(() {
      rehomeState.imageFile = dummyImgFile;
    });
    await tester.pump(const Duration(milliseconds: 500));

    // Tap Post button to submit
    final postBtn = find.widgetWithText(ElevatedButton, 'Post');
    await tester.tap(postBtn);
    await tester.pump(const Duration(seconds: 4));

    // Verify redirect back to New Friend page or tab index 0
    await waitForWidget(tester, find.text('New Friend'));

    // ─── 8. View Pet Profile ───
    // Click on the newly added pet or any pet card to view details
    final petCard = find.text('Rocky');
    if (petCard.evaluate().isNotEmpty) {
      await tester.tap(petCard.first);
      await tester.pump(const Duration(seconds: 2));
      // Verify detailed pet profile displays correct information
      expect(find.text('Rocky'), findsWidgets);
      expect(find.text('Traits'), findsWidgets);
      expect(find.text('Food Habit'), findsWidgets);
      // Go back
      await tester.tap(find.byType(IconButton).first);
      await tester.pump(const Duration(seconds: 2));
    }

    // ─── 9. Booking History (Appointment Management) ───
    // Go to Profile Tab
    await tapBottomNavBarTab(tester, 4);

    // Open booking history sheet
    final historyBtn = find.byTooltip('Booking & Order History');
    await waitForWidget(tester, historyBtn);
    await tester.tap(historyBtn);
    await tester.pump(const Duration(seconds: 2));

    // Verify our booked appointment is listed
    await waitForWidget(tester, find.text('Booking History'));
    expect(find.text('Milo'), findsWidgets);

    // Go back to Profile Page
    await tester.tap(find.byType(IconButton).first);
    await tester.pump(const Duration(seconds: 2));

    // ─── 10. Logout Flow ───
    final logoutBtn = find.byTooltip('Logout');
    await waitForWidget(tester, logoutBtn);
    await tester.tap(logoutBtn);
    await tester.pump(const Duration(seconds: 2));

    // Verify back on LoginMainPage or LoginPage
    await waitForWidget(tester, find.text('Welcome Back!'));
  });
}
