import processing.serial.*;

String serial_str = "COM3";
boolean bool_text = false;

int count = 7;
float size[] = new float[count];
float bulletX[] = new float[count];
float bulletY[]= new float[count];
float spd[] = new float[count];
float max=10;
float min=1;
int ground = 100;

float xf = 0.005;
float yf = 0.015;
float sky_zoff = 0.0;  
float zincrement = 0.02; 
float move;

float playX=100, playY=250;
float pW=10, pH=20;
int temp=10;
float humi=1;

String end = "GameOver";

boolean gameOver = false;
boolean hit = false;

PImage img_balloon;
PImage img_sky;
PImage img_bird;

Values th_val = null;


class Values extends Thread
{
  private Serial p;
  private byte[] buffer = new byte[10];
  private int humi = 0;
  private int noise = 0;
  private int x = 0;
  private int y = 0;
  private int temp = 0;
  private int data = 0;
  private boolean ready = false;

  public Values(Serial p)
  {
    this.p = p;
  }

  void run()
  {
    while (!isInterrupted())
    {
      if (p.available() > 0)
      {
        try
        {
          delay(100);

          data = p.read();
          if ((byte)data != -128)
          {
            continue;
          } else
          {
            buffer[0] = (byte)data;
            for (int i=1; i<10; i++)
            {
              data = p.read();
              buffer[i] = (byte)data;
            }
          }

          if ((buffer[0] != -128) || (buffer[9] != -127))
          {
            continue;
          }

          if (!checksum(buffer))
          {
            continue;
          }

          ready = true;
          temp = buffer[1];
          humi = buffer[2];
          noise = (buffer[3] * 256) + ((int)buffer[4]&(0x000000FF));
          x = (buffer[5] * 256) + ((int)buffer[6]&(0x000000FF));
          y = (buffer[7] * 256) + ((int)buffer[8]&(0x000000FF));
        }
        catch(ArrayIndexOutOfBoundsException e)
        {
          print("d ");
        }
      }
    }
  }

  private boolean checksum(byte[] byteArray)
  {
    byte temp = 0;

    for (byte val : byteArray)
    {
      temp += val;
    }

    if ((temp + (~temp+1)) == 0x00)
    {
      return true;
    }

    return false;
  }

  public int getHumi()
  {
    return humi;
  }

  public int getNoise()
  {
    return noise;
  }

  public int getTemp()
  {
    return temp;
  }

  public int getX()
  {
    return x;
  }

  public int getY()
  {
    return y;
  }

  public boolean getReady()
  {
    return ready;
  }

  public String getData()
  {
    String data = new String();

    for (byte b : buffer)
    {
      data += b;
      data += " ";
    }
    return data;
  }
}

void setup() {
  size(700, 500);
  img_balloon = loadImage("d:\\balloon.png");
  img_sky = loadImage("d:\\sky.jpg");
  img_bird = loadImage("d:\\bird.png");

  for (int i=0; i<count; i++) {
    size[i]=random(20, 40);
    //size[i] = 5;
    bulletX[i]=random(width, width+500);
    bulletY[i]=random(0, height);
    //spd[i]=random(0.5f, 2);
    spd[i]=random(1, 3);
  }
  th_val = new Values(new Serial(this, serial_str, 9600));
  th_val.start();
}

void draw() {
  //background(#3CD7FF);
  //sky();
  image(img_sky, width/2, height/2, width, height);

  for (int i=0; i<count; i++) {
    image(img_bird, bulletX[i], bulletY[i], size[i], size[i]);
    bulletX[i] -= spd[i]*humi;
    if (bulletX[i]<=0) {
      bulletX[i]=width;
      bulletY[i]=random(0, height);
    }
    if ((bulletX[i]>playX-pW && bulletX[i]<playX+pW)
      && (bulletY[i]>playY-pH && bulletY[i]<playY+pH)) {
      hit();
    } else {
      //reset();
    }
    if (hit) {
      textSize(50);
      text(end, width/2-100, height/2);
    }
  }
  player();
  sensor();
}

void player() {
  noStroke();
  rectMode(CENTER);
  rect(playX, playY, temp, temp);
  imageMode(CENTER);
  image(img_balloon, playX, playY, temp*3, temp*4);
}

void hit() {
  hit = true;
  print("hit");
  gameOver = true;
}

void reset() {
  hit = false;
}

void keyPressed() 
{
  if (!hit) {
    if (key == 'd')  bool_text = true;
    else if(key == 'e') bool_text = false;
  }
}

void sky() {
  loadPixels();
  move -= 0.01;
  float sky_xoff = move;
  for (int x = 0; x < width; x++) {
    sky_xoff += xf; 
    float sky_yoff = 0.0;
    for (int y = 0; y < height; y++) {
      sky_yoff += yf;
      float red = map(noise(sky_xoff, sky_yoff, sky_zoff), 0, 1, 10, 255);
      float green = map(noise(sky_xoff, sky_yoff, sky_zoff), 0, 1, 120, 255);
      float blue = map(noise(sky_xoff, sky_yoff, sky_zoff), 0, 1, 240, 255);
      pixels[x + y * width] = color(red, green, blue);
    }
  }
  updatePixels();
  sky_zoff += zincrement;
}

void sensor() {
  temp();
  humi();
  sound_move();
  if(bool_text)  test_text();
}

void sound_move() 
{
  int noise = th_val.getNoise();

  if (noise >= 50 && noise <= 53 ) {
    playY+=0.2;  
    if (playY>height) playY=height;
  } else if (noise==0) {
  } else {
    playY-=1;    
    if (playY<0) playY=0;
  }
}

void temp() {
  temp=th_val.getTemp();
}

void humi() {
  humi=(float)th_val.getHumi()/20;
}

void test_text() {
  int margin = 50;
  fill(0);
  textSize(20);
  text("data >> " + th_val.getData(), 20, margin*1);
  if (!th_val.getReady())
  {
    text("temp >> " + "Ready", 20, margin*2);
    text("humi >> " + "Ready", 20, margin*3);
    text("noise >> " + "Ready", 20, margin*4);
    text("x >> " + "Ready", 20, margin*5);
    text("y >> " + "Ready", 20, margin*6);
  } else
  {
    text("temp >> " + th_val.getTemp() + "℃", 20, margin*2);
    text("humi >> " + th_val.getHumi() + "%", 20, margin*3);
    text("noise >> " + th_val.getNoise(), 20, margin*4);
    text("x >> " + th_val.getX(), 20, margin*5);
    text("y >> " + th_val.getY(), 20, margin*6);
  }
}
