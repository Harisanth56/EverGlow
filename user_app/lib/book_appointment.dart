import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/my_booking.dart'; // Ensure this matches your route targets

class BookAppointment extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointment({super.key, required this.doctor});

  @override
  State<BookAppointment> createState() => _BookAppointmentState();
}

class _BookAppointmentState extends State<BookAppointment> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<bool> _insertAppointment() async {
    try {
      final supabase = Supabase.instance.client;

      // Format Date: YYYY-MM-DD
      final String formattedDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);

      // Format Time: HH:mm:ss (24-hour format)
      final String formattedTime =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      await supabase.from('tbl_appointment').insert({
        'appointment_date': formattedDate,
        'appointment_time': formattedTime,
        'appointment_status': 'pending',
        'user_id': supabase.auth.currentUser?.id,
        'dermatologist_id': widget.doctor['dermatologist_id'],
      });

      return true; // Success
    } catch (e) {
      debugPrint("Insert Error: $e");
      return false; // Failure
    }
  }

  // Function to pop out the Calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return _buildPickerTheme(child!);
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Clear selected time if changing date, to force re-validation
        _selectedTime = null; 
      });
    }
  }

  // Function to pop out the Clock with past-time validation
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay nowTime = TimeOfDay.now();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? nowTime,
      builder: (context, child) {
        return _buildPickerTheme(child!);
      },
    );

    if (picked != null && picked != _selectedTime) {
      // Check if the selected date is today
      if (_selectedDate != null) {
        final DateTime now = DateTime.now();
        final bool isToday = _selectedDate!.year == now.year &&
            _selectedDate!.month == now.month &&
            _selectedDate!.day == now.day;

        if (isToday) {
          // Compare hours and minutes to see if picked time is in the past
          if (picked.hour < nowTime.hour ||
              (picked.hour == nowTime.hour && picked.minute < nowTime.minute)) {
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot select a time that has already passed today."),
                backgroundColor: Colors.orangeAccent,
                duration: Duration(seconds: 2),
              ),
            );
            return; // Reject past time selection
          }
        }
      }

      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Custom Theme for Date/Time pickers to match your midnight theme
  Widget _buildPickerTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8E71FF), // Header background & selected circle
          onPrimary: Colors.white, // Header text
          surface: Color(0xFF161B22), // Background of picker
          onSurface: Colors.white, // Dates and text
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF8E71FF)),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.doctor['dermatologist_name'] ?? 'Doctor';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8E71FF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Book Appointment",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Consulting with Dr. $name",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),

            /// DATE COLUMN
            const Text(
              "Select Date",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSelectionTile(
              onTap: () => _selectDate(context),
              icon: Icons.calendar_today,
              value: _selectedDate == null
                  ? "Pick a date"
                  : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
            ),

            const SizedBox(height: 30),

            /// TIME COLUMN
            const Text(
              "Select Time",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSelectionTile(
              onTap: () => _selectTime(context),
              icon: Icons.access_time_filled,
              value: _selectedTime == null
                  ? "Pick a time"
                  : _selectedTime!.format(context),
            ),

            const Spacer(),

            /// CONFIRM BUTTON
            GestureDetector(
              onTap: (_selectedDate != null && _selectedTime != null)
                  ? () async {
                      // 1. Show Loading UI
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF8E71FF),
                          ),
                        ),
                      );

                      // 2. Call the Separate Function
                      bool isSuccess = await _insertAppointment();

                      if (!mounted) return;
                      Navigator.pop(context); // Close the loading dialog

                      if (isSuccess) {
                        // 3. Success Feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Appointment Booked Successfully!"),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // 4. Navigate back to Home and clear the stack
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyAppointments(),
                          ),
                          (route) => false,
                        );
                      } else {
                        // 5. Error Feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Failed to book appointment. Please try again.",
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  : null,
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: (_selectedDate != null && _selectedTime != null)
                        ? [const Color(0xFF6B4EE6), const Color(0xFF8E71FF)]
                        : [Colors.grey.shade900, Colors.grey.shade800],
                  ),
                  boxShadow: (_selectedDate != null && _selectedTime != null)
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6B4EE6).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : [],
                ),
                child: const Center(
                  child: Text(
                    'Confirm Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionTile({
    required VoidCallback onTap,
    required IconData icon,
    required String value,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8E71FF)),
            const SizedBox(width: 15),
            Text(
              value,
              style: TextStyle(
                color: value.contains("Pick") ? Colors.white38 : Colors.white,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}