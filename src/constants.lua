---@enum STATE
STATE = {
    NONE = 'NONE',
    WAITING_FOR_DIALOG = 'WAITING_FOR_DIALOG',
    WAITING_FOR_MENU = 'WAITING_FOR_MENU',
    WAITING_FOR_ATTACH = 'WAITING_FOR_ATTACH',
    WAITING_FOR_CLICK = 'WAITING_FOR_CLICK',
    WAITING_FOR_ITEM_DIALOG = 'WAITING_FOR_ITEM_DIALOG'
};

---@enum PATTERN
PATTERN = {
    ITEM_CLICK = 'mountain.testDrive.selectVehicle|%d',
    REGEX_PACKET = 'window%.executeEvent%(\'event%.(.+)\', `(.+)`%);',
    EVENT_ADD_ITEM = 'mountain.testDrive.addVehicles',
    EVENT_OPEN_MENU = 'mountain.testDrive.initializeText',
    MENU_TYPE_DEFAULT = 'Примерка аксессуаров (обычных)',
    MENU_TYPE_UNIQUE = 'Примерка аксессуаров (уникальных)',
    DIALOG_TITLE_ITEM_INFO = 'Примерка аксессуара',
    EVENT_SET_ACTIVE_VIEW = 'event.setActiveView',
    OPEN_MENU = 'onActiveViewChanged|MountainTestDrive',
    CLOSE_MENU = 'onActiveViewChanged|null',
    CLOSE_TESTDRIVE = 'mountain.testDrive.close'
};

---@enum MENU_TYPE
MENU_TYPE = {
    NONE = 'none',
    DEFAULT = 'default',
    UNIQUE = 'unique'
};

---@enum COMMAND
COMMAND = {
    TOGGLE = 'vacs.parser.start',
    SAVE = 'vacs.parser.save'
};

ITEM_CLICK_DELAY = 100;