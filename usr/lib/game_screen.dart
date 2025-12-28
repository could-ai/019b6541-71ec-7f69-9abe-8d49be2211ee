import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class Weapon {
  final String name;
  final int damage;
  final IconData icon;
  final Color color;

  const Weapon({
    required this.name,
    required this.damage,
    required this.icon,
    required this.color,
  });
}

class DamageText {
  final String id;
  final int damage;
  final double x;
  final double y;
  double opacity = 1.0;
  double offset = 0.0;

  DamageText({
    required this.id,
    required this.damage,
    required this.x,
    required this.y,
  });
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // 游戏数值
  static const int _initialHp = 1000;
  int _currentHp = _initialHp;
  bool _isDefeated = false;

  // 武器列表
  final List<Weapon> _weapons = [
    const Weapon(name: '普通拳头', damage: 10, icon: Icons.back_hand, color: Colors.brown),
    const Weapon(name: '铁剑', damage: 25, icon: Icons.gavel, color: Colors.blueGrey),
    const Weapon(name: '火焰魔法', damage: 50, icon: Icons.local_fire_department, color: Colors.orange),
    const Weapon(name: '昊天锤', damage: 100, icon: Icons.hardware, color: Colors.purple),
  ];

  late Weapon _selectedWeapon;

  // 动画控制
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  // 浮动伤害数字
  final List<DamageText> _damageTexts = [];

  @override
  void initState() {
    super.initState();
    _selectedWeapon = _weapons[0];

    // 初始化受击抖动动画
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _attack() {
    if (_isDefeated) return;

    // 播放抖动动画
    _shakeController.forward(from: 0);

    setState(() {
      _currentHp -= _selectedWeapon.damage;
      if (_currentHp <= 0) {
        _currentHp = 0;
        _isDefeated = true;
        _showVictoryDialog();
      }
      
      // 添加伤害数字效果
      _addDamageText(_selectedWeapon.damage);
    });
  }

  void _addDamageText(int damage) {
    final id = DateTime.now().toIso8601String() + Random().nextInt(1000).toString();
    // 随机位置偏移
    final randomX = Random().nextDouble() * 100 - 50; 
    final randomY = Random().nextDouble() * 50 - 25;

    final text = DamageText(
      id: id,
      damage: damage,
      x: randomX,
      y: randomY,
    );

    setState(() {
      _damageTexts.add(text);
    });

    // 简单的动画循环让数字飘起来
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        final index = _damageTexts.indexWhere((t) => t.id == id);
        if (index != -1) {
          _damageTexts[index].offset += 2.0; // 向上飘
          _damageTexts[index].opacity -= 0.02; // 变淡
          
          if (_damageTexts[index].opacity <= 0) {
            _damageTexts.removeAt(index);
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _restartGame() {
    setState(() {
      _currentHp = _initialHp;
      _isDefeated = false;
      _damageTexts.clear();
    });
    Navigator.of(context).pop();
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 胜利！'),
        content: const Text('你成功打败了栾灵犀！'),
        actions: [
          TextButton(
            onPressed: _restartGame,
            child: const Text('再打一次'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打败栾灵犀'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 顶部血条区域
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'BOSS: 栾灵犀',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _currentHp / _initialHp,
                    minHeight: 20,
                    backgroundColor: Colors.grey[300],
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'HP: $_currentHp / $_initialHp',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 中间战斗区域
          Expanded(
            child: GestureDetector(
              onTap: _attack,
              behavior: HitTestBehavior.opaque, // 确保点击整个区域都有效
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景点击提示
                  const Positioned(
                    bottom: 20,
                    child: Text(
                      '点击屏幕攻击！',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  // BOSS 形象
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          sin(_shakeController.value * pi * 4) * 10, 
                          0
                        ),
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: _isDefeated ? Colors.grey : Colors.red[100],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isDefeated ? Colors.grey : Colors.red,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Center(
                            child: _isDefeated 
                              ? const Icon(Icons.sentiment_very_dissatisfied, size: 100, color: Colors.white)
                              : const Icon(Icons.person, size: 100, color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isDefeated)
                          const Text(
                            '已击败',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),

                  // 伤害数字层
                  ..._damageTexts.map((text) {
                    return Positioned(
                      left: MediaQuery.of(context).size.width / 2 + text.x - 20, // 居中偏移
                      top: MediaQuery.of(context).size.height / 3 - text.offset + text.y,
                      child: Opacity(
                        opacity: text.opacity,
                        child: Text(
                          '-${text.damage}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                            shadows: const [
                              Shadow(
                                blurRadius: 2,
                                color: Colors.white,
                                offset: Offset(1, 1),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 底部武器选择区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择武器:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _weapons.map((weapon) {
                      final isSelected = _selectedWeapon == weapon;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedWeapon = weapon;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? weapon.color.withOpacity(0.2) : Colors.grey[100],
                              border: Border.all(
                                color: isSelected ? weapon.color : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  weapon.icon,
                                  color: isSelected ? weapon.color : Colors.grey,
                                  size: 30,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  weapon.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? weapon.color : Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '伤害: ${weapon.damage}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
