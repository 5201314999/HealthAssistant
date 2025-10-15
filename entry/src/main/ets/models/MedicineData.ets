// 药品数据模型
export class MedicineData {
  id: string = '';
  name: string = ''; // 药品名称
  specification: string = ''; // 规格
  dosage: string = ''; // 用法用量
  frequency: string[] = []; // 服用时间 ['morning', 'noon', 'evening', 'bedtime']
  reminderTimes: Map<string, RemindTime> = new Map(); // 每个时段的具体提醒时间
  startDate: number = 0;
  endDate: number = 0;
  stock: number = 0; // 库存数量
  note: string = '';
  reminderEnabled: boolean = true; // 是否启用提醒
  
  constructor() {
    this.id = Date.now().toString() + Math.random().toString(36).substr(2, 9);
    this.startDate = Date.now();
    this.endDate = Date.now() + 30 * 24 * 60 * 60 * 1000; // 默认30天
    // 初始化默认提醒时间
    this.reminderTimes.set('morning', { hour: 8, minute: 0 });
    this.reminderTimes.set('noon', { hour: 12, minute: 0 });
    this.reminderTimes.set('evening', { hour: 18, minute: 0 });
    this.reminderTimes.set('bedtime', { hour: 22, minute: 0 });
  }

  // 序列化为 JSON
  toJSON(): MedicineDataJSON {
    const reminderTimesObj: Record<string, RemindTime> = {};
    this.reminderTimes.forEach((value: RemindTime, key: string) => {
      reminderTimesObj[key] = value;
    });

    const result: MedicineDataJSON = {
      id: this.id,
      name: this.name,
      specification: this.specification,
      dosage: this.dosage,
      frequency: this.frequency,
      reminderTimesObj: reminderTimesObj,
      startDate: this.startDate,
      endDate: this.endDate,
      stock: this.stock,
      note: this.note,
      reminderEnabled: this.reminderEnabled
    };
    return result;
  }

  // 从 JSON 反序列化
  static fromJSON(json: MedicineDataJSON): MedicineData {
    const medicine = new MedicineData();
    medicine.id = json.id;
    medicine.name = json.name;
    medicine.specification = json.specification;
    medicine.dosage = json.dosage;
    medicine.frequency = json.frequency;
    medicine.startDate = json.startDate;
    medicine.endDate = json.endDate;
    medicine.stock = json.stock;
    medicine.note = json.note;
    medicine.reminderEnabled = json.reminderEnabled;

    // 处理 reminderTimes
    const reminderTimesObj = json.reminderTimesObj;
    if (reminderTimesObj) {
      medicine.reminderTimes = new Map();
      Object.keys(reminderTimesObj).forEach((key: string) => {
        medicine.reminderTimes.set(key, reminderTimesObj[key]);
      });
    }

    return medicine;
  }
}

// 用药记录
export class MedicineRecord {
  id: string = '';
  medicineId: string = '';
  medicineName: string = '';
  date: number = 0;
  time: 'morning' | 'noon' | 'evening' | 'bedtime' = 'morning';
  taken: boolean = false; // 是否已服用
  takenTime: number = 0; // 实际服用时间
  note: string = '';
  
  constructor(medicineId: string, medicineName: string, timeSlot: 'morning' | 'noon' | 'evening' | 'bedtime') {
    this.id = Date.now().toString() + Math.random().toString(36).substr(2, 9);
    this.medicineId = medicineId;
    this.medicineName = medicineName;
    this.date = Date.now();
    this.time = timeSlot;
  }
}

// 服用时间显示名称接口
export interface TimeNamesMap {
  morning: string;
  noon: string;
  evening: string;
  bedtime: string;
}

// 服用时间显示名称
export const TIME_NAMES: TimeNamesMap = {
  morning: '早上',
  noon: '中午',
  evening: '晚上',
  bedtime: '睡前'
};


export interface RemindTime {
  hour: number,
  minute: number
}

// 药品数据 JSON 接口
export interface MedicineDataJSON {
  id: string;
  name: string;
  specification: string;
  dosage: string;
  frequency: string[];
  reminderTimesObj: Record<string, RemindTime>;
  startDate: number;
  endDate: number;
  stock: number;
  note: string;
  reminderEnabled: boolean;
}

