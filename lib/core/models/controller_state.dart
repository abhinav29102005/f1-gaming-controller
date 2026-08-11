class ControllerState {
  double steering; // -1.0 (full left) to 1.0 (full right)
  double throttle; // 0.0 to 1.0
  double brake; // 0.0 to 1.0

  int currentGear; // 0 = Reverse, 1 = Neutral, 2 = 1st, 3 = 2nd ... 9 = 8th
  int dpad; // 0 = Centered, 1 = Up, 2 = Up-Right, 3 = Right, 4 = Down-Right, 5 = Down, 6 = Down-Left, 7 = Left, 8 = Up-Left

  // Button bit flags
  bool drs;
  bool ers;
  bool pitLimiter;
  bool radio;
  bool boxBox;
  bool engineMapUp;
  bool engineMapDown;
  bool paddleUpshift;
  bool paddleDownshift;

  // General face buttons
  bool buttonA;
  bool buttonB;
  bool buttonX;
  bool buttonY;
  bool buttonStart;
  bool buttonSelect;

  int playerId; // 0 = P1, 1 = P2, 2 = P3, 3 = P4

  ControllerState({
    this.steering = 0.0,
    this.throttle = 0.0,
    this.brake = 0.0,
    this.currentGear = 1, // Start in Neutral
    this.dpad = 0,
    this.drs = false,
    this.ers = false,
    this.pitLimiter = false,
    this.radio = false,
    this.boxBox = false,
    this.engineMapUp = false,
    this.engineMapDown = false,
    this.paddleUpshift = false,
    this.paddleDownshift = false,
    this.buttonA = false,
    this.buttonB = false,
    this.buttonX = false,
    this.buttonY = false,
    this.buttonStart = false,
    this.buttonSelect = false,
    this.playerId = 0,
  });

  void reset() {
    steering = 0.0;
    throttle = 0.0;
    brake = 0.0;
    currentGear = 1;
    dpad = 0;
    drs = false;
    ers = false;
    pitLimiter = false;
    radio = false;
    boxBox = false;
    engineMapUp = false;
    engineMapDown = false;
    paddleUpshift = false;
    paddleDownshift = false;
    buttonA = false;
    buttonB = false;
    buttonX = false;
    buttonY = false;
    buttonStart = false;
    buttonSelect = false;
  }

  // Pack 16 buttons into a 16-bit integer bitmask
  int get buttonBitmask {
    int mask = 0;
    if (drs) mask |= (1 << 0);
    if (ers) mask |= (1 << 1);
    if (pitLimiter) mask |= (1 << 2);
    if (radio) mask |= (1 << 3);
    if (boxBox) mask |= (1 << 4);
    if (engineMapUp) mask |= (1 << 5);
    if (engineMapDown) mask |= (1 << 6);
    if (paddleUpshift) mask |= (1 << 7);
    if (paddleDownshift) mask |= (1 << 8);
    if (buttonA) mask |= (1 << 9);
    if (buttonB) mask |= (1 << 10);
    if (buttonX) mask |= (1 << 11);
    if (buttonY) mask |= (1 << 12);
    if (buttonStart) mask |= (1 << 13);
    if (buttonSelect) mask |= (1 << 14);
    return mask;
  }
}
