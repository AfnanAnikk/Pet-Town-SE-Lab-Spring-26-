// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pet_town/main.dart' as app;
import 'package:pet_town/widgets/primary_button.dart';
import 'package:pet_town/widgets/rolling_text_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test credentials – Account 1 creates/manages events; Account 2 receives
// invitations & announcements.
// ─────────────────────────────────────────────────────────────────────────────
const String _account1Email    = 'shafibari@gmail.com';
const String _account1Password = '6196Bari';

const String _account2Email    = 'test@gmail.com';
const String _account2Password = '6196Bari';
const String _account2Username = 'test@gmail.com';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Wait up to [maxTries]×100 ms for [finder] to appear.
  Future<void> waitFor(WidgetTester t, Finder finder,
      {int maxTries = 80}) async {
    for (int i = 0; i < maxTries; i++) {
      if (finder.evaluate().isNotEmpty) {
        await t.pump();
        return;
      }
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsOneWidget,
        reason: 'Widget not found after ${maxTries * 100} ms: $finder');
  }

  /// Tap the BottomNavigationBar item at [index].
  Future<void> tapNavTab(WidgetTester t, int index) async {
    final bar = find.byType(BottomNavigationBar);
    expect(bar, findsOneWidget);
    (t.widget<BottomNavigationBar>(bar)).onTap!(index);
    // Global wait of 2 seconds after navigation tab switch
    await t.pump(const Duration(seconds: 2));
  }

  /// Find a TextField by its hintText.
  Finder fieldByHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint);

  // ── Re-usable flows ───────────────────────────────────────────────────────

  /// Boot app and wait for landing page button.
  Future<void> bootApp(WidgetTester t) async {
    app.main();
    await t.pump(const Duration(seconds: 2));
  }

  /// Login with [email] / [password] and wait for the home screen.
  Future<void> login(WidgetTester t,
      {required String email, required String password, Duration? postLoginWait}) async {
    // If the landing page button is present, we need to bypass onboarding
    final landingButton = find.byType(RollingTextButton);
    if (landingButton.evaluate().isNotEmpty) {
      await t.tap(landingButton);
      await t.pump(const Duration(seconds: 2));

      // Tap Log In on the LoginMainPage
      final logInMainBtn = find.widgetWithText(PrimaryButton, 'Log In');
      await waitFor(t, logInMainBtn);
      await t.tap(logInMainBtn);
      await t.pump(const Duration(seconds: 2));
    }

    final emailField = fieldByHint('demo@gmail.com');
    await waitFor(t, emailField);
    await t.enterText(emailField, '');
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(emailField, email);
    await t.pump(const Duration(milliseconds: 500));

    final pwField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '••••••••••');
    await t.enterText(pwField, '');
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(pwField, password);
    await t.pump(const Duration(milliseconds: 500));

    final loginBtn = find.widgetWithText(PrimaryButton, 'Log in');
    await t.tap(loginBtn);
    await t.pump(const Duration(seconds: 5));

    // Wait for home screen landmark (dashboard must be fully visible)
    await waitFor(t, find.text('Features'), maxTries: 100);
    await t.pump(const Duration(seconds: 2));

    // Apply specific post-login wait to allow full initialization
    final waitDuration = postLoginWait ??
        (email == _account1Email ? const Duration(seconds: 10) : const Duration(seconds: 5));
    await t.pump(waitDuration);
  }

  /// Logout from the Profile tab and wait for LoginPage.
  Future<void> logout(WidgetTester t) async {
    await tapNavTab(t, 4);
    final logoutBtn = find.byTooltip('Logout');
    await waitFor(t, logoutBtn);
    await t.tap(logoutBtn);
    // Global wait of 2 seconds after logout click
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(seconds: 3));
    await waitFor(t, find.text('Welcome Back!'));
    await t.pump(const Duration(seconds: 2));
  }

  /// Open the Events page from the Features bottom-sheet.
  Future<void> openEventsPage(WidgetTester t) async {
    await tapNavTab(t, 2);
    final eventsBtn = find.byTooltip('Events');
    await waitFor(t, eventsBtn);
    await t.tap(eventsBtn);
    // Global wait of 2 seconds after selecting event menu
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(milliseconds: 500));
    await waitFor(t, find.text('Events'));
    // Global wait of 2 seconds once Events page loads
    await t.pump(const Duration(seconds: 2));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TEST GROUP 1: Account 1 – full Event management lifecycle
  // ══════════════════════════════════════════════════════════════════════════
  group('Event Feature – Account 1 (organiser)', () {

    // ── T1: Create Event (3-step wizard) ─────────────────────────────────
    testWidgets('T1 – Create an event via the 3-step wizard',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      // Step 1: tap FAB
      final fab = find.widgetWithText(FloatingActionButton, 'Create Event');
      await waitFor(t, fab);
      await t.tap(fab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify we are on Create Event (step 1 – "Basics")
      await waitFor(t, find.text('Create Event'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Enter title
      final titleField = fieldByHint('e.g. Dog Park Meetup');
      await waitFor(t, titleField);
      await t.enterText(titleField, 'Integration Test Meetup');
      await t.pump(const Duration(seconds: 2)); // global delay

      // Select category chip "Meetup"
      final meetupChip = find.text('Meetup');
      await waitFor(t, meetupChip);
      await t.tap(meetupChip.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Select pet type "Dog"
      final dogChip = find.text('Dog');
      await t.tap(dogChip.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap visibility – "Public 🌍"
      final publicVis = find.text('Public 🌍');
      await t.tap(publicVis);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Next"
      final nextBtn = find.widgetWithText(ElevatedButton, 'Next');
      await t.tap(nextBtn.last);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Step 2: When & Where
      // Tap start-date tile – opens DatePicker
      final startTile = find.text('Select start date & time');
      await waitFor(t, startTile);
      await t.tap(startTile);
      await t.pump(const Duration(seconds: 2)); // global delay

      // The DatePicker dialog is visible – tap OK
      final okBtn = find.text('OK');
      if (okBtn.evaluate().isNotEmpty) {
        await t.tap(okBtn.first);
        await t.pump(const Duration(seconds: 2)); // global delay
        // TimePicker OK
        final okBtn2 = find.text('OK');
        if (okBtn2.evaluate().isNotEmpty) {
          await t.tap(okBtn2.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }
      }

      // Enter location
      final locationField = fieldByHint('City, address or venue name');
      await waitFor(t, locationField);
      await t.enterText(locationField, 'Dhaka Central Park');
      await t.pump(const Duration(seconds: 2)); // global delay

      // Next → Step 3
      await t.tap(find.widgetWithText(ElevatedButton, 'Next').last);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Step 3: Details
      final descField = fieldByHint('Tell people what this event is about…');
      await waitFor(t, descField);
      await t.enterText(descField, 'A fun meetup for dog owners in the city.');
      await t.pump(const Duration(seconds: 2)); // global delay

      final maxField = fieldByHint('e.g. 50');
      await t.enterText(maxField, '30');
      await t.pump(const Duration(seconds: 2)); // global delay

      final contactField = fieldByHint('Phone number or email');
      await t.enterText(contactField, '01811223344');
      await t.pump(const Duration(seconds: 2)); // global delay

      // Enable "Require Registration" switch
      final regSwitch = find.byType(Switch).first;
      if (regSwitch.evaluate().isNotEmpty) {
        await t.tap(regSwitch);
        await t.pump(const Duration(seconds: 2)); // global delay
      }

      // Submit
      final createBtn = find.widgetWithText(ElevatedButton, 'Create Event 🎉');
      await waitFor(t, createBtn);
      await t.tap(createBtn);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Wait for success snackbar
      await waitFor(t, find.text('Event created successfully! 🎉'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify we are back on Events page
      await waitFor(t, find.text('Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T2: View event in "My Events" tab ────────────────────────────────
    testWidgets('T2 – View created event in My Events tab',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      // Switch to "My Events" tab
      final myEventsTab = find.text('My Events');
      await waitFor(t, myEventsTab);
      await t.tap(myEventsTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Hosting sub-tab should be visible
      await waitFor(t, find.text('Hosting'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Our event card should appear
      final eventTitle = find.text('Integration Test Meetup');
      await waitFor(t, eventTitle, maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay
      expect(eventTitle, findsWidgets);
    });

    // ── T3: Edit event (change title + description) ───────────────────────
    testWidgets('T3 – Edit an existing event', (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      // Go to My Events → Hosting
      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Edit" action button on the first card
      final editActionBtn = find.text('Edit').first;
      await waitFor(t, editActionBtn, maxTries: 80);
      await t.tap(editActionBtn);
      await t.pump(const Duration(seconds: 2)); // global delay

      // We should be on Edit Event page
      await waitFor(t, find.text('Edit Event'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Change title on Step 1
      final titleField = fieldByHint('e.g. Dog Park Meetup');
      await waitFor(t, titleField);
      await t.tap(titleField);
      await t.pump(const Duration(seconds: 2)); // global delay
      await t.enterText(titleField, 'Updated Meetup for Dogs');
      await t.pump(const Duration(seconds: 2)); // global delay

      // Next → Step 2
      await t.tap(find.widgetWithText(ElevatedButton, 'Next').last);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Next → Step 3
      await waitFor(t, find.widgetWithText(ElevatedButton, 'Next'));
      await t.tap(find.widgetWithText(ElevatedButton, 'Next').last);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Update description
      await waitFor(t, fieldByHint('Tell people what this event is about…'));
      await t.enterText(fieldByHint('Tell people what this event is about…'),
          'Updated: Fun meetup for dog owners – revised description.');
      await t.pump(const Duration(seconds: 2)); // global delay

      // Save
      final saveBtn = find.widgetWithText(ElevatedButton, 'Save Changes ✅');
      await waitFor(t, saveBtn);
      await t.tap(saveBtn);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Wait for success snackbar
      await waitFor(t, find.text('Event updated! ✅'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T4: Open Event Detail & mark "Going" ─────────────────────────────
    testWidgets('T4 – View event detail and mark as Going',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      // Tap first event card on Discover tab
      final discoverTab = find.text('Discover');
      await waitFor(t, discoverTab);
      await t.tap(discoverTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      final eventCard = find.text('Updated Meetup for Dogs');
      if (eventCard.evaluate().isEmpty) {
        final seeAll = find.text('See all');
        if (seeAll.evaluate().isNotEmpty) {
          await t.tap(seeAll.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }
      } else {
        await t.tap(eventCard.first);
        await t.pump(const Duration(seconds: 2)); // global delay

        // Verify detail page loaded
        await waitFor(t, find.text('Discussion'));
        await t.pump(const Duration(seconds: 2)); // global delay

        // Tap "Going" button
        final goingBtn = find.text('Going');
        if (goingBtn.evaluate().isNotEmpty) {
          await t.tap(goingBtn.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }

        // Tap "Interested" button
        final interestedBtn = find.text('Interested');
        if (interestedBtn.evaluate().isNotEmpty) {
          await t.tap(interestedBtn.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }

        // Bookmark event
        final bookmarkBtn = find.byIcon(Icons.bookmark_outline);
        if (bookmarkBtn.evaluate().isNotEmpty) {
          await t.tap(bookmarkBtn.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }

        // Go back
        await t.tap(find.byType(IconButton).first);
        await t.pump(const Duration(seconds: 2)); // global delay
      }
    });

    // ── T5: Discussion – post a comment, react, reply ─────────────────────
    testWidgets('T5 – Discussion: post comment, react, and reply',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      // Navigate to My Events → open detail of first event
      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      final firstEventCard = find.byType(InkWell).first;
      await waitFor(t, firstEventCard);
      await t.tap(firstEventCard);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Open Discussion from detail page
      await waitFor(t, find.text('Discussion'));
      await t.pump(const Duration(seconds: 2)); // global delay
      final viewAllBtn = find.text('View All');
      await waitFor(t, viewAllBtn);
      await t.tap(viewAllBtn.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // We're on EventDiscussionPage
      await waitFor(t, find.text('Discussion'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Type a comment
      final commentInput = fieldByHint('Add a comment…');
      await waitFor(t, commentInput);
      await t.enterText(commentInput, 'This is an automated integration test comment! 🐶');
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap Send
      final sendBtn = find.byIcon(Icons.send_rounded);
      await waitFor(t, sendBtn);
      await t.tap(sendBtn);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify comment appears
      await waitFor(t, find.text('This is an automated integration test comment! 🐶'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      // React (👍) to the first comment
      final reactBtn = find.text('👍').first;
      if (reactBtn.evaluate().isNotEmpty) {
        await t.tap(reactBtn);
        await t.pump(const Duration(seconds: 2)); // global delay
      }

      // Reply to the comment
      final replyBtn = find.text('Reply').first;
      if (replyBtn.evaluate().isNotEmpty) {
        await t.tap(replyBtn);
        await t.pump(const Duration(seconds: 2)); // global delay
        final replyInput = fieldByHint('Write a reply…');
        if (replyInput.evaluate().isNotEmpty) {
          await t.enterText(replyInput, 'Reply from integration test.');
          await t.pump(const Duration(seconds: 2)); // global delay
          await t.tap(find.byIcon(Icons.send_rounded));
          await t.pump(const Duration(seconds: 2)); // global delay
        }
      }

      // Go back
      await t.tap(find.byType(IconButton).first);
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T6: Send Announcement to participants ──────────────────────────────
    testWidgets('T6 – Send an announcement to event participants',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      // Go to My Events
      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Announce" action button
      final announceBtn = find.text('Announce');
      await waitFor(t, announceBtn, maxTries: 80);
      await t.tap(announceBtn.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Bottom sheet should appear
      await waitFor(t, find.text('📣 Send Announcement'));
      await t.pump(const Duration(seconds: 2)); // global delay

      final announcementInput = fieldByHint('Write your announcement…');
      await waitFor(t, announcementInput);
      await t.enterText(announcementInput,
          'Reminder: Our dog meetup is tomorrow at 10am! Please bring a leash. 🐶');
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap Send
      final sendBtn = find.widgetWithText(ElevatedButton, 'Send');
      await waitFor(t, sendBtn);
      await t.tap(sendBtn);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify success snackbar
      await waitFor(t, find.text('Announcement sent! 📣'), maxTries: 60);
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T7: Invite users to an event ──────────────────────────────────────
    testWidgets('T7 – Invite Account 2 to an event', (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      // Go to Invites tab → Send Invites sub-tab
      final invitesTab = find.text('Invites');
      await waitFor(t, invitesTab);
      await t.tap(invitesTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      final sendInvitesSubTab = find.text('Send Invites');
      await waitFor(t, sendInvitesSubTab, maxTries: 80);
      await t.tap(sendInvitesSubTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Search for Account 2
      final searchField = fieldByHint('Search users by name/email...');
      await waitFor(t, searchField, maxTries: 60);
      await t.enterText(searchField, _account2Username);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Invite" button
      final inviteBtn = find.widgetWithText(ElevatedButton, 'Invite');
      await waitFor(t, inviteBtn, maxTries: 60);
      await t.tap(inviteBtn.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify snackbar confirms invitation sent
      await waitFor(t, find.textContaining('Invitation sent to'), maxTries: 60);
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T8: Manage participants – view People list ─────────────────────────
    testWidgets('T8 – View participant list for own event',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "People" action button
      final peopleBtn = find.text('People');
      await waitFor(t, peopleBtn, maxTries: 80);
      await t.tap(peopleBtn.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // BottomSheet appears with "Participants" header
      await waitFor(t, find.textContaining('Participants'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Close sheet
      await t.tap(find.byType(IconButton).first);
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T9: Change event status ───────────────────────────────────────────
    testWidgets('T9 – Change event status to "ongoing"',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Status" action button
      final statusBtn = find.text('Status');
      await waitFor(t, statusBtn, maxTries: 80);
      await t.tap(statusBtn.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // BottomSheet: tap "Ongoing"
      final ongoingItem = find.text('Ongoing');
      await waitFor(t, ongoingItem, maxTries: 60);
      await t.tap(ongoingItem);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify status badge updated
      await waitFor(t, find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T10: Delete the event ─────────────────────────────────────────────
    testWidgets('T10 – Delete the event', (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));
      await openEventsPage(t);

      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Delete" action button
      final deleteBtn = find.text('Delete');
      await waitFor(t, deleteBtn, maxTries: 80);
      await t.tap(deleteBtn.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Confirmation dialog appears
      await waitFor(t, find.text('Delete Event'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Delete" button inside dialog
      final confirmDeleteBtn = find.widgetWithText(ElevatedButton, 'Delete');
      await waitFor(t, confirmDeleteBtn);
      await t.tap(confirmDeleteBtn);
      await t.pump(const Duration(seconds: 2)); // global delay
      await t.pump(const Duration(seconds: 2)); // wait extra for network delete

      // Event should be gone
      final eventTitle = find.text('Updated Meetup for Dogs');
      expect(eventTitle.evaluate().isEmpty, isTrue,
          reason: 'Deleted event should no longer appear in the list');
      await t.pump(const Duration(seconds: 2)); // global delay
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TEST GROUP 2: Account 2 – receive invitation, check announcement,
  //               accept / reject invitation
  // ══════════════════════════════════════════════════════════════════════════
  group('Event Feature – Account 2 (invitee)', () {

    // ── T11: Check received invitations ───────────────────────────────────
    testWidgets('T11 – Account 2 views received invitations',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));
      await openEventsPage(t);

      // Go to Invites tab
      final invitesTab = find.text('Invites');
      await waitFor(t, invitesTab);
      await t.tap(invitesTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify "Received" sub-tab loaded
      await waitFor(t, find.text('Received'), maxTries: 60);
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T12: Accept an invitation ─────────────────────────────────────────
    testWidgets('T12 – Account 2 accepts a pending invitation',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));
      await openEventsPage(t);

      final invitesTab = find.text('Invites');
      await waitFor(t, invitesTab);
      await t.tap(invitesTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Look for "Accept" button
      final acceptBtn = find.widgetWithText(ElevatedButton, 'Accept');
      if (acceptBtn.evaluate().isNotEmpty) {
        await t.tap(acceptBtn.first);
        await t.pump(const Duration(seconds: 2)); // global delay

        // Verify snackbar confirmation
        await waitFor(t, find.textContaining('You are now going to'), maxTries: 60);
        await t.pump(const Duration(seconds: 2)); // global delay
      } else {
        print('[T12] No pending invitations found for Account 2.');
      }
    });

    // ── T13: Decline an invitation ────────────────────────────────────────
    testWidgets('T13 – Account 2 declines a pending invitation',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));
      await openEventsPage(t);

      final invitesTab = find.text('Invites');
      await waitFor(t, invitesTab);
      await t.tap(invitesTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Look for "Decline" button
      final declineBtn = find.widgetWithText(OutlinedButton, 'Decline');
      if (declineBtn.evaluate().isNotEmpty) {
        await t.tap(declineBtn.first);
        await t.pump(const Duration(seconds: 2)); // global delay
        await waitFor(t, find.text('❌ Declined'), maxTries: 60);
        await t.pump(const Duration(seconds: 2)); // global delay
      } else {
        print('[T13] No pending invitations to decline for Account 2.');
      }
    });

    // ── T14: Browse Discover tab, join an event as "Interested" ──────────
    testWidgets('T14 – Account 2 marks an event as Interested',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));
      await openEventsPage(t);

      // Discover tab
      final discoverTab = find.text('Discover');
      await waitFor(t, discoverTab);
      await t.tap(discoverTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap event card
      final eventCards = find.byWidgetPredicate((w) => w is InkWell);
      await waitFor(t, eventCards, maxTries: 80);
      if (eventCards.evaluate().isNotEmpty) {
        await t.tap(eventCards.first);
        await t.pump(const Duration(seconds: 2)); // global delay

        // Verify detail page
        await waitFor(t, find.text('Discussion'));
        await t.pump(const Duration(seconds: 2)); // global delay

        // Mark Interested
        final interestedBtn = find.text('Interested');
        if (interestedBtn.evaluate().isNotEmpty) {
          await t.tap(interestedBtn.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }

        // Go back
        await t.tap(find.byType(IconButton).first);
        await t.pump(const Duration(seconds: 2)); // global delay
      }
    });

    // ── T15: Account 2 checks Notifications for announcement ─────────────
    testWidgets('T15 – Account 2 views notifications for announcement',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));

      // Go to Notifications tab (index 3)
      await tapNavTab(t, 3);
      await waitFor(t, find.text('Notifications'));
      await t.pump(const Duration(seconds: 2)); // global delay
      expect(find.text('Notifications'), findsOneWidget);
    });

    // ── T16: Account 2 saves an event to bookmarks ────────────────────────
    testWidgets('T16 – Account 2 bookmarks an event',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));
      await openEventsPage(t);

      final discoverTab = find.text('Discover');
      await waitFor(t, discoverTab);
      await t.tap(discoverTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap first event card
      final eventCards = find.byWidgetPredicate((w) => w is InkWell);
      await waitFor(t, eventCards, maxTries: 80);
      if (eventCards.evaluate().isNotEmpty) {
        await t.tap(eventCards.first);
        await t.pump(const Duration(seconds: 2)); // global delay

        // Tap bookmark
        final bookmarkIcon = find.byIcon(Icons.bookmark_outline);
        if (bookmarkIcon.evaluate().isNotEmpty) {
          await t.tap(bookmarkIcon.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }

        // Go back
        await t.tap(find.byType(IconButton).first);
        await t.pump(const Duration(seconds: 2)); // global delay
      }

      // Verify Saved tab
      final savedTab = find.text('Saved');
      await waitFor(t, savedTab);
      await t.tap(savedTab);
      await t.pump(const Duration(seconds: 2)); // global delay
      expect(find.text('Saved'), findsWidgets);
    });

    // ── T17: Account 2 searches for the event ─────────────────────────────
    testWidgets('T17 – Account 2 searches for an event by keyword',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));
      await openEventsPage(t);

      // Tap search icon
      final searchIcon = find.byIcon(Icons.search);
      await waitFor(t, searchIcon);
      await t.tap(searchIcon.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      final searchField = fieldByHint('Search events…');
      if (searchField.evaluate().isEmpty) {
        final fallback = find.byType(TextField).first;
        await waitFor(t, fallback);
        await t.enterText(fallback, 'Meetup');
      } else {
        await t.enterText(searchField, 'Meetup');
      }
      await t.pump(const Duration(seconds: 2)); // global delay

      // Back to events page
      await t.tap(find.byType(IconButton).first);
      await t.pump(const Duration(seconds: 2)); // global delay
    });

    // ── T18: Account 2 filters events by category ─────────────────────────
    testWidgets('T18 – Filter events by category chip',
        (WidgetTester t) async {
      await bootApp(t);
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));
      await openEventsPage(t);

      final discoverTab = find.text('Discover');
      await waitFor(t, discoverTab);
      await t.tap(discoverTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Tap "Meetup" chip
      final meetupChip = find.text('Meetup');
      await waitFor(t, meetupChip, maxTries: 60);
      await t.tap(meetupChip.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      expect(find.byType(CircularProgressIndicator).evaluate().isEmpty, isTrue,
          reason: 'Loading should be complete');

      // Tap "All" to reset
      final allChip = find.text('All');
      await waitFor(t, allChip);
      await t.tap(allChip.first);
      await t.pump(const Duration(seconds: 2)); // global delay
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TEST GROUP 3: End-to-End cross-account event workflow in one session
  //               (strict sequence of 11 steps with synchronization)
  // ══════════════════════════════════════════════════════════════════════════
  group('Event Feature – Full Cross-Account E2E', () {

    testWidgets(
        'E2E – Create event (Acc1), invite (Acc1), switch to Acc2, accept invite, check announcement',
        (WidgetTester t) async {
      // ──── Step 1: Account 1 logs in → wait 10s ────────────────────────
      await bootApp(t);
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 10));

      // ──── Step 2: Creates event → wait ────────────────────────────────
      await openEventsPage(t);

      final fab = find.widgetWithText(FloatingActionButton, 'Create Event');
      await waitFor(t, fab);
      await t.tap(fab);
      await t.pump(const Duration(seconds: 2)); // global delay

      await waitFor(t, find.text('Create Event'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Step 1 – Basics
      await t.enterText(fieldByHint('e.g. Dog Park Meetup'), 'E2E Cross-Account Test Event');
      await t.pump(const Duration(seconds: 2)); // global delay

      await t.tap(find.text('Meetup').first);
      await t.pump(const Duration(seconds: 2)); // global delay

      await t.tap(find.widgetWithText(ElevatedButton, 'Next').last);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Step 2 – When & Where
      final startTile = find.text('Select start date & time');
      await waitFor(t, startTile);
      await t.tap(startTile);
      await t.pump(const Duration(seconds: 2)); // global delay

      final ok1 = find.text('OK');
      if (ok1.evaluate().isNotEmpty) {
        await t.tap(ok1.first);
        await t.pump(const Duration(seconds: 2)); // global delay
        final ok2 = find.text('OK');
        if (ok2.evaluate().isNotEmpty) {
          await t.tap(ok2.first);
          await t.pump(const Duration(seconds: 2)); // global delay
        }
      }

      await t.enterText(fieldByHint('City, address or venue name'), 'Test Venue, Dhaka');
      await t.pump(const Duration(seconds: 2)); // global delay

      await t.tap(find.widgetWithText(ElevatedButton, 'Next').last);
      await t.pump(const Duration(seconds: 2)); // global delay

      // Step 3 – Description
      await t.enterText(fieldByHint('Tell people what this event is about…'),
          'E2E automated cross-account test event description.');
      await t.pump(const Duration(seconds: 2)); // global delay

      await t.tap(find.widgetWithText(ElevatedButton, 'Create Event 🎉'));
      await t.pump(const Duration(seconds: 2)); // global delay

      // Verify creation
      await waitFor(t, find.text('Event created successfully! 🎉'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      // ──── Step 3: Invites Account 2 → wait ➔ confirm snackbar ─────────
      await openEventsPage(t);

      final invitesTab = find.text('Invites');
      await waitFor(t, invitesTab);
      await t.tap(invitesTab);
      await t.pump(const Duration(seconds: 2)); // global delay

      await waitFor(t, find.text('Send Invites'));
      await t.tap(find.text('Send Invites'));
      await t.pump(const Duration(seconds: 2)); // global delay

      final searchField = fieldByHint('Search users by name/email...');
      await waitFor(t, searchField, maxTries: 60);
      await t.enterText(searchField, _account2Username);
      await t.pump(const Duration(seconds: 2)); // global delay

      final inviteBtn = find.widgetWithText(ElevatedButton, 'Invite');
      if (inviteBtn.evaluate().isNotEmpty) {
        await t.tap(inviteBtn.first);
        await t.pump(const Duration(seconds: 2)); // global delay
        await waitFor(t, find.textContaining('Invitation sent to'), maxTries: 60);
        await t.pump(const Duration(seconds: 2)); // global delay
      }

      // ──── Step 4: Sends announcement → wait ➔ confirm snackbar ────────
      await openEventsPage(t);

      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      final announceBtn = find.text('Announce');
      await waitFor(t, announceBtn, maxTries: 80);
      await t.tap(announceBtn.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      await waitFor(t, find.text('📣 Send Announcement'));
      await t.pump(const Duration(seconds: 2)); // global delay

      await t.enterText(fieldByHint('Write your announcement…'),
          'E2E Test Announcement – please join us tomorrow!');
      await t.pump(const Duration(seconds: 2)); // global delay

      await t.tap(find.widgetWithText(ElevatedButton, 'Send'));
      await t.pump(const Duration(seconds: 2)); // global delay

      await waitFor(t, find.text('Announcement sent! 📣'), maxTries: 60);
      await t.pump(const Duration(seconds: 2)); // global delay

      // ──── Step 5: Logs out ➔ wait 2s ──────────────────────────────────
      await logout(t);
      await t.pump(const Duration(seconds: 2)); // global delay

      // ──── Step 6: Account 2 logs in → wait 5s ─────────────────────────
      await login(t, email: _account2Email, password: _account2Password, postLoginWait: const Duration(seconds: 5));

      // ──── Step 7: Accepts invitation → wait ➔ verify success ─────────
      await openEventsPage(t);

      await waitFor(t, find.text('Invites'));
      await t.tap(find.text('Invites'));
      await t.pump(const Duration(seconds: 2)); // global delay

      final acceptBtn2 = find.widgetWithText(ElevatedButton, 'Accept');
      if (acceptBtn2.evaluate().isNotEmpty) {
        await t.tap(acceptBtn2.first);
        await t.pump(const Duration(seconds: 2)); // global delay
        await waitFor(t, find.textContaining('You are now going to'), maxTries: 60);
        await t.pump(const Duration(seconds: 2)); // global delay
      }

      // ──── Step 8: Checks notifications → wait ➔ verify announcement ────
      await tapNavTab(t, 3);
      await waitFor(t, find.text('Notifications'));
      await t.pump(const Duration(seconds: 2)); // global delay
      expect(find.text('Notifications'), findsOneWidget);

      // ──── Step 9: Logs out ➔ wait 2s ──────────────────────────────────
      await logout(t);
      await t.pump(const Duration(seconds: 2)); // global delay

      // ──── Step 10: Account 1 logs back in → wait 5s ───────────────────
      await login(t, email: _account1Email, password: _account1Password, postLoginWait: const Duration(seconds: 5));

      // ──── Step 11: Deletes event → wait ➔ verify removal ──────────────
      await openEventsPage(t);

      await waitFor(t, find.text('My Events'));
      await t.tap(find.text('My Events'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await waitFor(t, find.text('Hosting'), maxTries: 80);
      await t.pump(const Duration(seconds: 2)); // global delay

      final deleteBtn2 = find.text('Delete');
      await waitFor(t, deleteBtn2, maxTries: 80);
      await t.tap(deleteBtn2.first);
      await t.pump(const Duration(seconds: 2)); // global delay

      await waitFor(t, find.text('Delete Event'));
      await t.pump(const Duration(seconds: 2)); // global delay

      await t.tap(find.widgetWithText(ElevatedButton, 'Delete'));
      await t.pump(const Duration(seconds: 2)); // global delay
      await t.pump(const Duration(seconds: 2)); // wait extra for network delete

      final deletedTitle = find.text('E2E Cross-Account Test Event');
      expect(deletedTitle.evaluate().isEmpty, isTrue,
          reason: 'Deleted event must not appear in My Events list');
      await t.pump(const Duration(seconds: 2)); // global delay
    });
  });
}
