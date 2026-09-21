import 'package:flutter/widgets.dart';

/// 应用文案。locale 为空时由 Flutter 自动使用系统语言。
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
    Locale('fr'),
    Locale('de'),
    Locale('nl'),
    Locale('es'),
    Locale('ko'),
    Locale('ja'),
    Locale('it'),
    Locale('ru'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String _t(String key) =>
      (_texts[locale.languageCode]?[key] ??
      _texts['en']?[key] ??
      _texts['zh']![key])!;

  String _f(String key, Map<String, Object> values) {
    var result = _t(key);
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return result;
  }

  String get appTitle => _t('appTitle');
  String get settingsLoadFailed => _t('settingsLoadFailed');
  String get settingsSaveFailed => _t('settingsSaveFailed');
  String get roundTime => _t('roundTime');
  String seconds(int value) => _f('seconds', {'value': value});
  String get challengeRounds => _t('challengeRounds');
  String rounds(int value) => _f('rounds', {'value': value});
  String get emsConnected => _t('emsConnected');
  String get emsPenaltyTitle => _t('emsPenaltyTitle');
  String get emsConnectedDescription => _t('emsConnectedDescription');
  String get emsNotConnectedDescription => _t('emsNotConnectedDescription');
  String get manageConnectedDevice => _t('manageConnectedDevice');
  String get connectEmsDevice => _t('connectEmsDevice');
  String get firstFailureIntensity => _t('firstFailureIntensity');
  String get failureIncrement => _t('failureIncrement');
  String get preparing => _t('preparing');
  String get startChallenge => _t('startChallenge');
  String get deviceConnection => _t('deviceConnection');
  String get connectEms => _t('connectEms');
  String connectedDevice(String name) => _f('connectedDevice', {'name': name});
  String get scanYycDj => _t('scanYycDj');
  String get processing => _t('processing');
  String get disconnectDevice => _t('disconnectDevice');
  String get scanAndConnectEms => _t('scanAndConnectEms');
  String get connectionSafety => _t('connectionSafety');
  String get endChallengeQuestion => _t('endChallengeQuestion');
  String get stay => _t('stay');
  String get endChallenge => _t('endChallenge');
  String get pause => _t('pause');
  String get cameraNotReady => _t('cameraNotReady');
  String get retry => _t('retry');
  String get challengePaused => _t('challengePaused');
  String get continueChallenge => _t('continueChallenge');
  String get emsPenaltyRunning => _t('emsPenaltyRunning');
  String get emsPenaltyCompleted => _t('emsPenaltyCompleted');
  String get challengeFailed => _t('challengeFailed');
  String get waitPenalty => _t('waitPenalty');
  String get finishSeeResult => _t('finishSeeResult');
  String get finishContinue => _t('finishContinue');
  String get challengeComplete => _t('challengeComplete');
  String result(int passed, int failed) =>
      _f('result', {'passed': passed, 'failed': failed});
  String get back => _t('back');
  String get targetPose => _t('targetPose');
  String combo(int step, int length) =>
      _f('combo', {'step': step, 'length': length});
  String get poseSuccess => _t('poseSuccess');
  String countdown(int value) => _f('countdown', {'value': value});
  String get waitingForPlayer => _t('waitingForPlayer');
  String get getInFrame => _t('getInFrame');
  String get holdStill => _t('holdStill');
  String get keepAdjusting => _t('keepAdjusting');
  String get actionStatus => _t('actionStatus');
  String get noDevicePenalty => _t('noDevicePenalty');
  String get deviceConnectedMessage => _t('deviceConnectedMessage');
  String get deviceDisconnectedMessage => _t('deviceDisconnectedMessage');
  String get noDeviceFoundMessage => _t('noDeviceFoundMessage');
  String get connectionFailedMessage => _t('connectionFailedMessage');

  String translateConnectionMessage(String message) {
    switch (message) {
      case '设备已连接，可以开始挑战':
        return deviceConnectedMessage;
      case '设备已断开':
        return deviceDisconnectedMessage;
      case '没有找到设备，请确认设备已开机并靠近手机':
        return noDeviceFoundMessage;
      case '连接失败，请确认蓝牙权限和设备状态':
        return connectionFailedMessage;
      default:
        return message;
    }
  }

  String translateCameraError(String message) {
    switch (message) {
      case '请在安卓或 iPhone 上运行':
        return _t('cameraUnsupported');
      case '未找到前置摄像头':
        return _t('frontCameraMissing');
      case '无法使用摄像头，请在系统设置中允许相机权限':
        return _t('cameraPermission');
      case '摄像头启动失败，请重试':
        return _t('cameraStartFailed');
      case '动作识别暂不可用，请重新启动摄像头':
        return _t('poseDetectionUnavailable');
      default:
        return message;
    }
  }

  String pose(String key) => _t(key);

  static const _texts = <String, Map<String, String>>{
    'zh': {
      'appTitle': '役次元-姿势快闪',
      'settingsLoadFailed': '设置读取失败，已使用默认设置',
      'settingsSaveFailed': '设置未保存，本局仍使用当前设置',
      'roundTime': '每轮时间',
      'seconds': '{value} 秒',
      'challengeRounds': '挑战轮数',
      'rounds': '{value} 轮',
      'emsConnected': 'EMS 已连接',
      'emsPenaltyTitle': '失败时执行 EMS 惩罚',
      'emsConnectedDescription': '返回后连接仍会保留，挑战失败时自动执行惩罚',
      'emsNotConnectedDescription': '请先连接设备，再开始挑战并确认佩戴安全',
      'manageConnectedDevice': '管理连接设备',
      'connectEmsDevice': '连接 EMS 设备',
      'firstFailureIntensity': '首次失败强度',
      'failureIncrement': '每次失败增加',
      'preparing': '正在准备',
      'startChallenge': '开始挑战',
      'deviceConnection': '设备连接',
      'connectEms': '连接 EMS 设备',
      'connectedDevice': '已连接 {name}',
      'scanYycDj': '自动扫描 YYC-DJ 设备',
      'processing': '正在处理...',
      'disconnectDevice': '断开设备',
      'scanAndConnectEms': '扫描并连接 EMS',
      'connectionSafety': '连接后失败惩罚会自动执行。请先确认电极片、佩戴位置和强度设置安全。',
      'endChallengeQuestion': '结束本次挑战？',
      'stay': '留下',
      'endChallenge': '结束挑战',
      'pause': '暂停',
      'cameraNotReady': '摄像头未就绪',
      'retry': '重试',
      'challengePaused': '挑战已暂停',
      'continueChallenge': '继续挑战',
      'emsPenaltyRunning': 'EMS 惩罚执行中',
      'emsPenaltyCompleted': 'EMS 惩罚已完成',
      'challengeFailed': '挑战失败',
      'waitPenalty': '请等待本轮惩罚完成',
      'finishSeeResult': '完成，查看结果',
      'finishContinue': '完成，继续挑战',
      'challengeComplete': '挑战完成',
      'result': '成功 {passed} 轮  ·  失败 {failed} 轮',
      'back': '返回',
      'targetPose': '目标动作',
      'combo': '连续动作 {step}/{length}',
      'poseSuccess': '动作达成！',
      'countdown': '准备 {value}',
      'waitingForPlayer': '等待入镜',
      'getInFrame': '等你入镜',
      'holdStill': '保持住，不要动',
      'keepAdjusting': '继续调整',
      'actionStatus': '动作状态',
      'noDevicePenalty': '设备未连接，本次惩罚未发送',
      'deviceConnectedMessage': '设备已连接，可以开始挑战',
      'deviceDisconnectedMessage': '设备已断开',
      'noDeviceFoundMessage': '没有找到设备，请确认设备已开机并靠近手机',
      'connectionFailedMessage': '连接失败，请确认蓝牙权限和设备状态',
      'cameraUnsupported': '请在安卓或 iPhone 上运行',
      'frontCameraMissing': '未找到前置摄像头',
      'cameraPermission': '无法使用摄像头，请在系统设置中允许相机权限',
      'cameraStartFailed': '摄像头启动失败，请重试',
      'poseDetectionUnavailable': '动作识别暂不可用，请重新启动摄像头',
      'poseReach': '双手举高',
      'poseWings': '双臂平举',
      'poseGoalpost': '双臂投降',
      'poseHips': '双手叉腰',
      'poseReachWing': '一手举高，一手平举',
      'poseReachHip': '一手举高，一手叉腰',
      'poseDown': '双臂自然下垂',
      'poseCross': '双手抱胸',
      'poseClap': '双手合十',
      'poseWingGoalpost': '一手平举，一手投降',
      'poseWingHip': '一手平举，一手叉腰',
      'poseReachGoalpost': '一手举高，一手投降',
      'poseSingleReach': '单手举高',
      'poseSideLean': '向侧面倾斜',
      'poseOneLeg': '单腿抬起',
      'poseHandsHead': '双手抱头',
      'poseSquat': '半蹲',
      'poseStar': '星形站姿',
    },
    'en': {
      'appTitle': 'Pose Flash',
      'settingsLoadFailed': 'Could not load settings. Defaults are being used.',
      'settingsSaveFailed':
          'Settings were not saved; this challenge will use the current settings.',
      'roundTime': 'Time per round',
      'seconds': '{value} sec',
      'challengeRounds': 'Challenge rounds',
      'rounds': '{value} rounds',
      'emsConnected': 'EMS connected',
      'emsPenaltyTitle': 'EMS penalty on failure',
      'emsConnectedDescription':
          'The connection stays active and penalties run automatically on failure.',
      'emsNotConnectedDescription':
          'Connect a device before starting, and confirm it is safe to wear.',
      'manageConnectedDevice': 'Manage connected device',
      'connectEmsDevice': 'Connect EMS device',
      'firstFailureIntensity': 'First failure intensity',
      'failureIncrement': 'Increase per failure',
      'preparing': 'Preparing',
      'startChallenge': 'Start challenge',
      'deviceConnection': 'Device connection',
      'connectEms': 'Connect EMS device',
      'connectedDevice': 'Connected: {name}',
      'scanYycDj': 'Scan for YYC-DJ devices',
      'processing': 'Processing...',
      'disconnectDevice': 'Disconnect device',
      'scanAndConnectEms': 'Scan and connect EMS',
      'connectionSafety':
          'Penalties run automatically after connection. Confirm the pads, placement, and intensity are safe first.',
      'endChallengeQuestion': 'End this challenge?',
      'stay': 'Stay',
      'endChallenge': 'End challenge',
      'pause': 'Pause',
      'cameraNotReady': 'Camera not ready',
      'retry': 'Retry',
      'challengePaused': 'Challenge paused',
      'continueChallenge': 'Continue challenge',
      'emsPenaltyRunning': 'EMS penalty running',
      'emsPenaltyCompleted': 'EMS penalty complete',
      'challengeFailed': 'Challenge failed',
      'waitPenalty': 'Please wait for this penalty to finish',
      'finishSeeResult': 'Finish, see results',
      'finishContinue': 'Finish, continue',
      'challengeComplete': 'Challenge complete',
      'result': '{passed} passed  ·  {failed} failed',
      'back': 'Back',
      'targetPose': 'Target pose',
      'combo': 'Combo {step}/{length}',
      'poseSuccess': 'Pose matched!',
      'countdown': 'Get ready {value}',
      'waitingForPlayer': 'Waiting for you',
      'getInFrame': 'Step into frame',
      'holdStill': 'Hold still',
      'keepAdjusting': 'Keep adjusting',
      'actionStatus': 'Pose status',
      'noDevicePenalty': 'No device connected; penalty was not sent',
      'deviceConnectedMessage': 'Device connected. You can start.',
      'deviceDisconnectedMessage': 'Device disconnected',
      'noDeviceFoundMessage': 'No device found. Make sure it is on and nearby.',
      'connectionFailedMessage':
          'Connection failed. Check Bluetooth permission and device status.',
      'cameraUnsupported': 'Run this app on Android or iPhone',
      'frontCameraMissing': 'No front camera found',
      'cameraPermission':
          'Camera unavailable. Allow camera access in system settings.',
      'cameraStartFailed': 'Camera failed to start. Try again.',
      'poseDetectionUnavailable':
          'Pose detection is unavailable. Restart the camera.',
      'poseReach': 'Both hands up',
      'poseWings': 'Arms out',
      'poseGoalpost': 'Arms up',
      'poseHips': 'Hands on hips',
      'poseReachWing': 'One hand up, one arm out',
      'poseReachHip': 'One hand up, one hand on hip',
      'poseDown': 'Arms down',
      'poseCross': 'Arms crossed',
      'poseClap': 'Hands together',
      'poseWingGoalpost': 'One arm out, one arm up',
      'poseWingHip': 'One arm out, one hand on hip',
      'poseReachGoalpost': 'One hand up, one arm up',
      'poseSingleReach': 'One hand up',
      'poseSideLean': 'Side lean',
      'poseOneLeg': 'One leg up',
      'poseHandsHead': 'Hands on head',
      'poseSquat': 'Half squat',
      'poseStar': 'Star pose',
    },
    'fr': {
      'appTitle': 'Pose Flash',
      'settingsLoadFailed':
          'Impossible de charger les réglages. Valeurs par défaut utilisées.',
      'settingsSaveFailed':
          'Réglages non enregistrés ; les réglages actuels seront utilisés.',
      'roundTime': 'Durée de chaque manche',
      'seconds': '{value} s',
      'challengeRounds': 'Manches',
      'rounds': '{value} manches',
      'emsConnected': 'EMS connecté',
      'emsPenaltyTitle': 'Pénalité EMS en cas d’échec',
      'emsConnectedDescription':
          'La connexion reste active et la pénalité est automatique en cas d’échec.',
      'emsNotConnectedDescription':
          'Connectez un appareil avant de commencer et vérifiez qu’il peut être porté sans danger.',
      'manageConnectedDevice': 'Gérer l’appareil connecté',
      'connectEmsDevice': 'Connecter un appareil EMS',
      'firstFailureIntensity': 'Intensité du premier échec',
      'failureIncrement': 'Augmentation par échec',
      'preparing': 'Préparation',
      'startChallenge': 'Commencer',
      'deviceConnection': 'Connexion de l’appareil',
      'connectEms': 'Connecter un appareil EMS',
      'connectedDevice': 'Connecté : {name}',
      'scanYycDj': 'Rechercher les appareils YYC-DJ',
      'processing': 'Traitement...',
      'disconnectDevice': 'Déconnecter',
      'scanAndConnectEms': 'Rechercher et connecter EMS',
      'connectionSafety':
          'Après connexion, les pénalités sont automatiques. Vérifiez les électrodes, le placement et l’intensité.',
      'endChallengeQuestion': 'Terminer cette manche ?',
      'stay': 'Rester',
      'endChallenge': 'Terminer',
      'pause': 'Pause',
      'cameraNotReady': 'Caméra indisponible',
      'retry': 'Réessayer',
      'challengePaused': 'Défi en pause',
      'continueChallenge': 'Continuer',
      'emsPenaltyRunning': 'Pénalité EMS en cours',
      'emsPenaltyCompleted': 'Pénalité EMS terminée',
      'challengeFailed': 'Défi échoué',
      'waitPenalty': 'Attendez la fin de la pénalité',
      'finishSeeResult': 'Terminer, voir les résultats',
      'finishContinue': 'Terminer, continuer',
      'challengeComplete': 'Défi terminé',
      'result': '{passed} réussies  ·  {failed} échouées',
      'back': 'Retour',
      'targetPose': 'Pose cible',
      'combo': 'Enchaînement {step}/{length}',
      'poseSuccess': 'Pose réussie !',
      'countdown': 'Préparez-vous {value}',
      'waitingForPlayer': 'En attente',
      'getInFrame': 'Entrez dans le cadre',
      'holdStill': 'Ne bougez plus',
      'keepAdjusting': 'Ajustez encore',
      'actionStatus': 'État de la pose',
      'noDevicePenalty': 'Aucun appareil connecté ; pénalité non envoyée',
      'deviceConnectedMessage': 'Appareil connecté, vous pouvez commencer',
      'deviceDisconnectedMessage': 'Appareil déconnecté',
      'noDeviceFoundMessage':
          'Aucun appareil trouvé. Vérifiez qu’il est allumé et proche.',
      'connectionFailedMessage':
          'Échec de connexion. Vérifiez le Bluetooth et l’appareil.',
      'cameraUnsupported': 'Utilisez Android ou un iPhone',
      'frontCameraMissing': 'Caméra avant introuvable',
      'cameraPermission':
          'Caméra inaccessible. Autorisez-la dans les réglages.',
      'cameraStartFailed': 'Échec du démarrage de la caméra. Réessayez.',
      'poseDetectionUnavailable':
          'Détection indisponible. Redémarrez la caméra.',
      'poseReach': 'Deux mains en l’air',
      'poseWings': 'Bras écartés',
      'poseGoalpost': 'Bras levés',
      'poseHips': 'Mains sur les hanches',
      'poseReachWing': 'Une main en l’air, un bras écarté',
      'poseReachHip': 'Une main en l’air, une main sur la hanche',
      'poseDown': 'Bras le long du corps',
      'poseCross': 'Bras croisés',
      'poseClap': 'Mains jointes',
      'poseWingGoalpost': 'Un bras écarté, un bras levé',
      'poseWingHip': 'Un bras écarté, une main sur la hanche',
      'poseReachGoalpost': 'Une main en l’air, un bras levé',
      'poseSingleReach': 'Une main en l’air',
      'poseSideLean': 'Inclinaison latérale',
      'poseOneLeg': 'Une jambe levée',
      'poseHandsHead': 'Mains sur la tête',
      'poseSquat': 'Demi-squat',
      'poseStar': 'Position étoile',
    },
    'de': {
      'appTitle': 'Pose Flash',
      'roundTime': 'Zeit pro Runde',
      'seconds': '{value} Sek.',
      'challengeRounds': 'Runden',
      'rounds': '{value} Runden',
      'emsConnected': 'EMS verbunden',
      'emsPenaltyTitle': 'EMS-Strafe bei Fehler',
      'manageConnectedDevice': 'Verbundene Geräte',
      'connectEmsDevice': 'EMS-Gerät verbinden',
      'preparing': 'Vorbereitung',
      'startChallenge': 'Challenge starten',
      'deviceConnection': 'Geräteverbindung',
      'connectEms': 'EMS-Gerät verbinden',
      'processing': 'Wird verarbeitet...',
      'disconnectDevice': 'Gerät trennen',
      'scanAndConnectEms': 'EMS suchen und verbinden',
      'endChallengeQuestion': 'Challenge beenden?',
      'stay': 'Bleiben',
      'endChallenge': 'Beenden',
      'pause': 'Pause',
      'cameraNotReady': 'Kamera nicht bereit',
      'retry': 'Erneut versuchen',
      'challengePaused': 'Challenge pausiert',
      'continueChallenge': 'Fortsetzen',
      'challengeComplete': 'Challenge abgeschlossen',
      'back': 'Zurück',
      'targetPose': 'Zielpose',
      'poseSuccess': 'Pose geschafft!',
      'waitingForPlayer': 'Warte auf dich',
      'getInFrame': 'Ins Bild treten',
      'holdStill': 'Stillhalten',
      'keepAdjusting': 'Weiter anpassen',
      'actionStatus': 'Posenstatus',
    },
    'nl': {
      'appTitle': 'Pose Flash',
      'roundTime': 'Tijd per ronde',
      'seconds': '{value} sec.',
      'challengeRounds': 'Rondes',
      'rounds': '{value} rondes',
      'emsConnected': 'EMS verbonden',
      'emsPenaltyTitle': 'EMS-straf bij een fout',
      'manageConnectedDevice': 'Verbonden apparaat beheren',
      'connectEmsDevice': 'EMS-apparaat verbinden',
      'preparing': 'Voorbereiden',
      'startChallenge': 'Uitdaging starten',
      'deviceConnection': 'Apparaatverbinding',
      'connectEms': 'EMS-apparaat verbinden',
      'processing': 'Bezig...',
      'disconnectDevice': 'Apparaat loskoppelen',
      'scanAndConnectEms': 'EMS zoeken en verbinden',
      'endChallengeQuestion': 'Uitdaging beëindigen?',
      'stay': 'Blijven',
      'endChallenge': 'Beëindigen',
      'pause': 'Pauzeren',
      'cameraNotReady': 'Camera niet gereed',
      'retry': 'Opnieuw',
      'challengePaused': 'Uitdaging gepauzeerd',
      'continueChallenge': 'Doorgaan',
      'challengeComplete': 'Uitdaging voltooid',
      'back': 'Terug',
      'targetPose': 'Doelhouding',
      'poseSuccess': 'Houding gelukt!',
      'waitingForPlayer': 'Wachten op jou',
      'getInFrame': 'Ga in beeld staan',
      'holdStill': 'Blijf stil',
      'keepAdjusting': 'Blijf aanpassen',
      'actionStatus': 'Houdingstatus',
    },
    'es': {
      'appTitle': 'Pose Flash',
      'roundTime': 'Tiempo por ronda',
      'seconds': '{value} s',
      'challengeRounds': 'Rondas',
      'rounds': '{value} rondas',
      'emsConnected': 'EMS conectado',
      'emsPenaltyTitle': 'Penalización EMS al fallar',
      'manageConnectedDevice': 'Gestionar dispositivo',
      'connectEmsDevice': 'Conectar dispositivo EMS',
      'preparing': 'Preparando',
      'startChallenge': 'Iniciar desafío',
      'deviceConnection': 'Conexión del dispositivo',
      'connectEms': 'Conectar dispositivo EMS',
      'processing': 'Procesando...',
      'disconnectDevice': 'Desconectar dispositivo',
      'scanAndConnectEms': 'Buscar y conectar EMS',
      'endChallengeQuestion': '¿Terminar este desafío?',
      'stay': 'Quedarme',
      'endChallenge': 'Terminar',
      'pause': 'Pausa',
      'cameraNotReady': 'Cámara no lista',
      'retry': 'Reintentar',
      'challengePaused': 'Desafío pausado',
      'continueChallenge': 'Continuar',
      'challengeComplete': 'Desafío completado',
      'back': 'Volver',
      'targetPose': 'Postura objetivo',
      'poseSuccess': '¡Postura correcta!',
      'waitingForPlayer': 'Esperando',
      'getInFrame': 'Entra en el encuadre',
      'holdStill': 'No te muevas',
      'keepAdjusting': 'Sigue ajustando',
      'actionStatus': 'Estado de la postura',
    },
    'ko': {
      'appTitle': '포즈 플래시',
      'roundTime': '라운드 시간',
      'seconds': '{value}초',
      'challengeRounds': '도전 라운드',
      'rounds': '{value}라운드',
      'emsConnected': 'EMS 연결됨',
      'emsPenaltyTitle': '실패 시 EMS 페널티',
      'manageConnectedDevice': '연결 기기 관리',
      'connectEmsDevice': 'EMS 기기 연결',
      'preparing': '준비 중',
      'startChallenge': '도전 시작',
      'deviceConnection': '기기 연결',
      'connectEms': 'EMS 기기 연결',
      'processing': '처리 중...',
      'disconnectDevice': '기기 연결 해제',
      'scanAndConnectEms': 'EMS 검색 및 연결',
      'endChallengeQuestion': '도전을 종료할까요?',
      'stay': '남기',
      'endChallenge': '종료',
      'pause': '일시정지',
      'cameraNotReady': '카메라 준비 안 됨',
      'retry': '다시 시도',
      'challengePaused': '도전 일시정지',
      'continueChallenge': '계속하기',
      'challengeComplete': '도전 완료',
      'back': '돌아가기',
      'targetPose': '목표 포즈',
      'poseSuccess': '포즈 성공!',
      'waitingForPlayer': '대기 중',
      'getInFrame': '화면 안으로 들어오세요',
      'holdStill': '움직이지 마세요',
      'keepAdjusting': '계속 조정하세요',
      'actionStatus': '포즈 상태',
    },
    'ja': {
      'appTitle': 'ポーズフラッシュ',
      'roundTime': 'ラウンド時間',
      'seconds': '{value}秒',
      'challengeRounds': 'チャレンジ回数',
      'rounds': '{value}回',
      'emsConnected': 'EMS接続済み',
      'emsPenaltyTitle': '失敗時にEMSペナルティ',
      'manageConnectedDevice': '接続機器を管理',
      'connectEmsDevice': 'EMS機器を接続',
      'preparing': '準備中',
      'startChallenge': 'チャレンジ開始',
      'deviceConnection': '機器接続',
      'connectEms': 'EMS機器を接続',
      'processing': '処理中...',
      'disconnectDevice': '機器を切断',
      'scanAndConnectEms': 'EMSを検索して接続',
      'endChallengeQuestion': 'チャレンジを終了しますか？',
      'stay': '残る',
      'endChallenge': '終了',
      'pause': '一時停止',
      'cameraNotReady': 'カメラの準備ができていません',
      'retry': '再試行',
      'challengePaused': 'チャレンジは一時停止中',
      'continueChallenge': '続ける',
      'challengeComplete': 'チャレンジ完了',
      'back': '戻る',
      'targetPose': '目標ポーズ',
      'poseSuccess': 'ポーズ成功！',
      'waitingForPlayer': '待機中',
      'getInFrame': '画面に入ってください',
      'holdStill': '動かないでください',
      'keepAdjusting': '調整を続けてください',
      'actionStatus': 'ポーズ状態',
    },
    'it': {
      'appTitle': 'Pose Flash',
      'roundTime': 'Tempo per round',
      'seconds': '{value} sec',
      'challengeRounds': 'Round',
      'rounds': '{value} round',
      'emsConnected': 'EMS connesso',
      'emsPenaltyTitle': 'Penalità EMS in caso di errore',
      'manageConnectedDevice': 'Gestisci dispositivo',
      'connectEmsDevice': 'Collega dispositivo EMS',
      'preparing': 'Preparazione',
      'startChallenge': 'Inizia sfida',
      'deviceConnection': 'Connessione dispositivo',
      'connectEms': 'Collega dispositivo EMS',
      'processing': 'Elaborazione...',
      'disconnectDevice': 'Disconnetti dispositivo',
      'scanAndConnectEms': 'Cerca e collega EMS',
      'endChallengeQuestion': 'Terminare questa sfida?',
      'stay': 'Resta',
      'endChallenge': 'Termina',
      'pause': 'Pausa',
      'cameraNotReady': 'Fotocamera non pronta',
      'retry': 'Riprova',
      'challengePaused': 'Sfida in pausa',
      'continueChallenge': 'Continua',
      'challengeComplete': 'Sfida completata',
      'back': 'Indietro',
      'targetPose': 'Posizione obiettivo',
      'poseSuccess': 'Posizione riuscita!',
      'waitingForPlayer': 'In attesa',
      'getInFrame': 'Entra nell’inquadratura',
      'holdStill': 'Resta fermo',
      'keepAdjusting': 'Continua a regolare',
      'actionStatus': 'Stato posizione',
    },
    'ru': {
      'appTitle': 'Pose Flash',
      'roundTime': 'Время раунда',
      'seconds': '{value} сек.',
      'challengeRounds': 'Раунды',
      'rounds': '{value} раундов',
      'emsConnected': 'EMS подключён',
      'emsPenaltyTitle': 'EMS-наказание при ошибке',
      'manageConnectedDevice': 'Управление устройством',
      'connectEmsDevice': 'Подключить EMS',
      'preparing': 'Подготовка',
      'startChallenge': 'Начать испытание',
      'deviceConnection': 'Подключение устройства',
      'connectEms': 'Подключить EMS',
      'processing': 'Обработка...',
      'disconnectDevice': 'Отключить устройство',
      'scanAndConnectEms': 'Найти и подключить EMS',
      'endChallengeQuestion': 'Завершить испытание?',
      'stay': 'Остаться',
      'endChallenge': 'Завершить',
      'pause': 'Пауза',
      'cameraNotReady': 'Камера не готова',
      'retry': 'Повторить',
      'challengePaused': 'Испытание приостановлено',
      'continueChallenge': 'Продолжить',
      'challengeComplete': 'Испытание завершено',
      'back': 'Назад',
      'targetPose': 'Целевая поза',
      'poseSuccess': 'Поза выполнена!',
      'waitingForPlayer': 'Ожидание',
      'getInFrame': 'Встаньте в кадр',
      'holdStill': 'Не двигайтесь',
      'keepAdjusting': 'Продолжайте настройку',
      'actionStatus': 'Состояние позы',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
