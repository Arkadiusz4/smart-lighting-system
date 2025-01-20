import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/account/account_bloc.dart';
import 'package:mobile_app/blocs/account/account_event.dart';
import 'package:mobile_app/blocs/account/account_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/blocs/auth/auth_bloc.dart';
import 'package:mobile_app/blocs/auth/auth_event.dart';
import 'package:mobile_app/styles/color.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        } else if (state is AccountSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<AuthBloc>().add(AuthStarted());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Twoje Konto',
            style: TextStyle(
              color: Colors.white, // Replace with your textColor
              fontSize: 24.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Container(
          color: darkBackground, // Replace with your darkBackground
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 70,
                child: Icon(Icons.person, size: 100, color: primaryColor), // Replace primaryColor as needed
              ),
              const SizedBox(height: 15),
              Card(
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
                child: ListTile(
                  leading: const Icon(Icons.email, color: primaryColor), // Replace primaryColor as needed
                  title: Text(
                    user?.email ?? 'Brak danych',
                    style: const TextStyle(fontSize: 18, color: textColor), // Replace textColor as needed
                  ),
                ),
              ),
              const SizedBox(height: 80),
              BlocBuilder<AccountBloc, AccountState>(
                builder: (context, state) {
                  if (state is AccountLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Wyloguj'),
                            onPressed: () {
                              context.read<AccountBloc>().add(AccountLogoutRequested());
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            icon: const Icon(Icons.delete),
                            label: const Text('Usuń konto'),
                            onPressed: () {
                              // Capture the AccountBloc reference before opening the dialog
                              final accountBloc = context.read<AccountBloc>();

                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Potwierdzenie'),
                                  content: const Text(
                                    'Czy na pewno chcesz usunąć konto? Ta operacja jest nieodwracalna.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(),
                                      child: const Text('Anuluj'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                        // Use the captured accountBloc instead of reading from context
                                        accountBloc.add(AccountDeleteRequested());
                                      },
                                      child: const Text('Usuń'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                            ),
                            icon: const Icon(Icons.lock_reset),
                            label: const Text('Zmień hasło'),
                            onPressed: () {
                              _showChangePasswordDialog(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController newPasswordController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Zmień hasło'),
        content: TextField(
          controller: newPasswordController,
          obscureText: true,
          style: const TextStyle(
            color: Colors.black, // Kolor tekstu wpisanego w polu
          ),
          decoration: const InputDecoration(
            labelText: 'Nowe hasło',
            labelStyle: TextStyle(
              color: Colors.black, // Kolor tekstu etykiety
            ),
            filled: true,               // Włącza wypełnienie tła
            fillColor: Colors.black12,  // Ustawia kolor tła pola (użyj Colors.black dla czystej czerni)
            border: OutlineInputBorder(), // Opcjonalnie: ramka dla lepszej widoczności
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () async {
              final newPassword = newPasswordController.text.trim();
              if (newPassword.isNotEmpty) {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.updatePassword(newPassword);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hasło zostało zmienione.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Błąd: ${e.toString()}')),
                  );
                }
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Zmień'),
          ),
        ],
      ),
    );
  }
}
