import 'package:flutter/material.dart';

class UserInfoScreen extends StatelessWidget {
  final Map<String, dynamic> jwtPayload;
  final Map<String, dynamic>? statsData;
  final Map<String, dynamic>? balanceData;

  const UserInfoScreen({
    super.key,
    required this.jwtPayload,
    this.statsData,
    this.balanceData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 40,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF005D99),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (String value) {
                          switch (value) {
                            case 'profile':
                              print('Profile selected');
                              break;
                            case 'payment history':
                              print('Payment History selected');
                              break;
                            case 'logout':
                              print('Logout selected');
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF005D99),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text('Profile'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'payment history',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.receipt,
                                  color: Color(0xFF005D99),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text('Payment History'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: Color(0xFF005D99),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF005D99),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30, width: MediaQuery.of(context).size.width),
              Container(
                alignment: Alignment.centerLeft,
                child: RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Welcome,\n',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: jwtPayload['common_name'] ?? 'Not available',
                        style: const TextStyle(
                          color: Color(0xFF005D99),
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: const Color(0xFF005D99),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Current balance',
                      style: TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      balanceData?['data']?['creditAmount']?.toString() ?? '0',
                      style: const TextStyle(
                        color: Color(0xFFC2E7FF),
                        fontSize: 42,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 160,
                width: double.infinity,
                padding: const EdgeInsets.all(50),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5FF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Top-up balance',
                      style: TextStyle(
                        color: Color(0xFF4C4C4C),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005D99),
                        foregroundColor: const Color(0xFFC2E7FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Recharge'),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Services',
                style: TextStyle(
                  color: Color(0xFF005D99),
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/sign-document');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFE5F5FF),
                      ),
                      width: 140,
                      height: 140,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icon_sign_document.png',
                            color: const Color(0xFF005D99),
                            scale: 2,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Sign Document",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF005D99),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFE5F5FF),
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon_verify_document.png',
                          color: const Color(0xFF005D99),
                          scale: 2,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Verify Document",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF005D99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFE5F5FF),
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon_create_invitation.png',
                          color: const Color(0xFF005D99),
                          scale: 2,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Create Invitation",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF005D99),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFE5F5FF),
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon_manage_invitation.png',
                          color: const Color(0xFF005D99),
                          scale: 2,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Manage Invitation",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF005D99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Status',
                style: TextStyle(
                  color: Color(0xFF005D99),
                  fontSize: 30,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFE5F5FF),
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Today",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF005D99),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${statsData?['data']?['today'] ?? 0}",
                          style: const TextStyle(
                            fontSize: 36,
                            color: Color(0xFF005D99),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFE5F5FF),
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "This Month",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF005D99),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${statsData?['data']?['thisMonth'] ?? 0}",
                          style: const TextStyle(
                            fontSize: 36,
                            color: Color(0xFF005D99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFE5F5FF),
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "This year",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF005D99),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${statsData?['data']?['thisYear'] ?? 0}",
                          style: const TextStyle(
                            fontSize: 36,
                            color: Color(0xFF005D99),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFFE5F5FF),
                    ),
                    width: 140,
                    height: 140,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF005D99),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${statsData?['data']?['total'] ?? 0}",
                          style: const TextStyle(
                            fontSize: 36,
                            color: Color(0xFF005D99),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code),
            label: 'QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        selectedItemColor: const Color(0xFF005D99),
        backgroundColor: const Color(0xFFC2E7FF),
      ),
    );
  }
}
