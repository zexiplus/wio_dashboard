#include <rpcBLEDevice.h>
#include <BLEServer.h>
#include "TFT_eSPI.h"
#include <SPI.h>
#include "LIS3DHTR.h"

LIS3DHTR<TwoWire> lis; // 加速度传感器

using namespace std;

#define SERVICE_UUID "188f"
#define CHARACTERISTIC_UUID "2a19"
#define DESCRIPTOR_UUID "4545"

TFT_eSPI tft;

BLEServer *pServer = NULL;

const char *device_name = "wio terminal";
bool deviceConnected = false;

bool relayOn = false;

int sensorPin = A0; // A0 接传感器

class MyServerCallbacks : public BLEServerCallbacks
{
  void onConnect(BLEServer *pServer)
  {
    deviceConnected = true;
    tft.fillScreen(TFT_GREEN);
    tft.setTextColor(TFT_WHITE, TFT_BLACK);
    tft.setTextSize(3);
    tft.drawString(device_name, 40, 100);
    tft.setTextSize(2);
    tft.drawString("connected", 40, 140);
  };

  void onDisconnect(BLEServer *pServer)
  {
    deviceConnected = false;
    tft.fillScreen(TFT_ORANGE);
    tft.setTextColor(TFT_WHITE, TFT_BLACK);
    tft.setTextSize(3);
    tft.drawString(device_name, 40, 100);
    tft.setTextSize(2);
    tft.drawString("waiting for connecting...", 40, 140);
  };
};

// 继承 BLECharacteristicCallbacks 基类
class MyCallbacks : public BLECharacteristicCallbacks
{
  void onWrite(BLECharacteristic *pCharacteristic)
  {
    string rxValue = pCharacteristic->getValue();

    if (rxValue.length() > 0)
    {
      Serial.print("Received Value: ");
      Serial.println(rxValue.c_str());
    }

    if (!rxValue.compare("buzzer"))
    {
      analogWrite(WIO_BUZZER, 128);
      delay(1000);
      analogWrite(WIO_BUZZER, 0);
      delay(1000);
    }

    if (!rxValue.compare("relay on"))
    {
      digitalWrite(PIN_WIRE_SCL, HIGH);
    }

    if (!rxValue.compare("relay off"))
    {
      digitalWrite(PIN_WIRE_SCL, LOW);
    }
  }

  void onRead(BLECharacteristic *pCharacteristic)
  {
    float light = analogRead(WIO_LIGHT);
    float x_values, y_values, z_values;
    x_values = lis.getAccelerationX();
    y_values = lis.getAccelerationY();
    z_values = lis.getAccelerationZ();
    float analogSensorValue = analogRead(sensorPin);

    pCharacteristic->setValue(to_string(light) + ",x:" + to_string(x_values) + " y:" + to_string(y_values) + " z: " + to_string(z_values) + "," + to_string(analogSensorValue));
    Serial.println(light);
    Serial.println(x_values);
    Serial.println(y_values);
    Serial.println(z_values);
    Serial.println(analogSensorValue);
  }
};

void setup()
{
  // 初始化屏幕
  tft.begin();
  tft.init();
  tft.setRotation(3);
  tft.fillScreen(TFT_ORANGE);
  tft.setTextSize(3);
  tft.drawString(device_name, 40, 100);
  tft.setTextSize(2);
  tft.drawString("waiting for connecting...", 40, 140);

  Serial.begin(115200);

  pinMode(WIO_BUZZER, OUTPUT); // 初始化蜂鸣器

  pinMode(WIO_LIGHT, INPUT); // 初始化光线传感器

  pinMode(PIN_WIRE_SCL, OUTPUT); // 初始化寄存器

  lis.begin(Wire1); // 初始化加速度传感器
  lis.setOutputDataRate(LIS3DHTR_DATARATE_25HZ);
  lis.setFullScaleRange(LIS3DHTR_RANGE_2G);

  // 初始化设备名称, 服务,特征
  BLEDevice::init(device_name);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  BLECharacteristic *pCharacteristic = pService->createCharacteristic(
      CHARACTERISTIC_UUID,
      BLECharacteristic::PROPERTY_READ |
          BLECharacteristic::PROPERTY_WRITE);

  pCharacteristic->setAccessPermissions(GATT_PERM_READ | GATT_PERM_WRITE); // 设置权限

  BLEDescriptor *pDescriptor = pCharacteristic->createDescriptor(
      DESCRIPTOR_UUID,
      ATTRIB_FLAG_VOID | ATTRIB_FLAG_ASCII_Z,
      GATT_PERM_READ | GATT_PERM_WRITE,
      2);
  pCharacteristic->setValue("This is wio terminal");

  // 设置回调函数
  pCharacteristic->setCallbacks(new MyCallbacks());

  // 开始广播
  pService->start();
  pServer->getAdvertising()->start();

  // BLEAdvertising *pAdvertising = pServer->getAdvertising();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06); // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Characteristic defined! Now you can read it in your phone!");
}

void loop()
{
  delay(2000);
};
