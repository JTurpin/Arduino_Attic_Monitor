// EtherShield webserver demo
#include "EtherShield.h"
#include <stdlib.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// define inputs for fans
int frontfan = 5;
int backfan = 4;

#define ONE_WIRE_BUS 6  // Data wire is plugged into pin 6 on the Arduino
OneWire oneWire(ONE_WIRE_BUS);  // Setup a oneWire instance to communicate with any OneWire devices 
DallasTemperature sensors(&oneWire); // Pass our oneWire reference to Dallas Temperature.

// please modify the following two lines. mac and ip have to be unique
// in your local area network. You can not have the same numbers in
// two devices:
static uint8_t mymac[6] = {
  0x54,0x55,0x58,0x10,0x00,0x85}; 
  
static uint8_t myip[4] = {
  192,168,230,21};

#define MYWWWPORT 80
#define BUFFER_SIZE 550
static uint8_t buf[BUFFER_SIZE+1];

// The ethernet shield
EtherShield es=EtherShield();

uint16_t http200ok(void)
{
  return(es.ES_fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 200 OK\r\nContent-Type: text/html\r\nPragma: no-cache\r\n\r\n")));
}

// prepare the webpage by writing the data to the tcp send buffer
uint16_t print_webpage(uint8_t *buf)
{
  String Output1;
  float garageTempf = 0.0; 
  char garageTempc[7];
  int i=0;
  uint16_t plen;
  plen=http200ok();
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<html><head><title>Jim's Attic</title></head><body>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<center><h1>Welcome to Jim's Attic</h1>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<hr><h2><font color=\"red\">"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br> The Front Fan is: "));
  ///////  READING CT sensor 10 times and get average reading, fan off == ~600 ADC
  int CTarray1[11];
  float IsItOn = 0;
  for (int x = 0; x < 10; x++) { 
    CTarray1[x]=analogRead(frontfan);
    Serial.print("Front Fan reading ");
    Serial.print(x);
    Serial.print(" is: ");
    Serial.println(CTarray1[x]);
  }
  
  for (int y = 0; y < 10; y++) {
    if (CTarray1[y] < 330)
    {
      IsItOn = IsItOn + 10;
    }
    else if (CTarray1[y] < 700 && CTarray1[y] > 330 )
    {
      IsItOn = IsItOn + 1;
    }
    else
    {
      IsItOn = IsItOn + 10;
    }
  }
  IsItOn = IsItOn / 10;
  Serial.print("IsItOn == ");
  Serial.println(IsItOn);
  //////
  if ( IsItOn > 1 )
  { // The fan is on because the average eq >1
    Output1 = "ON";
    Serial.println("the font fan is on");
  }
  else if ( IsItOn == 1 )
  {
    Output1 = "OFF";
    Serial.println("the front fan is off");
  }
  else
  {
    Output1 = "Unknown";
    Serial.println("the front fan is unknown");
  }
  i=0;
    while (Output1[i]) {
                buf[TCP_CHECKSUM_L_P+3+plen]=Output1[i++];
                plen++;
        }
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br> The Back Fan is: "));
  ///////
  // READ Current sensor 2
  //////
  int CTarray2[11];
  IsItOn = 0;
  for (int x = 0; x < 10; x++) { 
    CTarray2[x]=analogRead(backfan);
    Serial.print("Back Fan reading ");
    Serial.print(x);
    Serial.print(" is: ");
    Serial.println(CTarray2[x]);
  }
  
  for (int y = 0; y < 10; y++) {
    if (CTarray2[y] < 330)
    {
      IsItOn = IsItOn + 10;
    }
    else if (CTarray2[y] < 700 && CTarray2[y] > 330 )
    {
      IsItOn = IsItOn + 1;
    }
    else
    {
      IsItOn = IsItOn + 10;
    }
  }
  IsItOn = IsItOn / 10;
  Serial.print("IsItOn == ");
  Serial.println(IsItOn);
  
  if ( IsItOn > 1 )
  { // The fan is on because the average eq >=1
    Output1 = "ON";
    Serial.println("the back fan is on");
  }
  else if ( IsItOn == 1 )
  {
    Output1 = "OFF";
    Serial.println("the back fan is off");
  }
    else
  {
    Output1 = "Unknown";
    Serial.println("the back fan is unknown");
  }
  i=0;
    while (Output1[i]) {
                buf[TCP_CHECKSUM_L_P+3+plen]=Output1[i++];
                plen++;
        }
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br>The Temp is: ") );
  sensors.requestTemperatures(); // Send the command to get temperatures
  garageTempf = DallasTemperature::toFahrenheit(sensors.getTempCByIndex(0));
  dtostrf(garageTempf, 3, 2, garageTempc);
  Serial.println(garageTempf); 
  i=0;
  while (garageTempc[i]) {
               buf[TCP_CHECKSUM_L_P+3+plen]=garageTempc[i++];
               plen++;
       }
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("<br></font></h2>") );
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("</center><hr>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("V1.0 <a href=\"http://www.stuffjimmakes.com\">http://www.stuffjimmakes.com</a>"));
  plen=es.ES_fill_tcp_data_p(buf,plen,PSTR("</body></html>"));

  return(plen);
}


void setup(){
  Serial.begin(9600);
  // Initialise SPI interface
  es.ES_enc28j60SpiInit();
  // initialize enc28j60
  es.ES_enc28j60Init(mymac,8);
  // init the ethernet/ip layer:
  es.ES_init_ip_arp_udp_tcp(mymac,myip, MYWWWPORT);
  sensors.begin();      // Start up the library
}

void loop(){
  uint16_t plen, dat_p;

  while(1) {
    // read packet, handle ping and wait for a tcp packet:
    dat_p=es.ES_packetloop_icmp_tcp(buf,es.ES_enc28j60PacketReceive(BUFFER_SIZE, buf));

    /* dat_p will be unequal to zero if there is a valid 
     * http get */
    if(dat_p==0){
      // no http request
      continue;
    }
    // tcp port 80 begin
    if (strncmp("GET ",(char *)&(buf[dat_p]),4)!=0){
      // head, post and other methods:
      dat_p=http200ok();
      dat_p=es.ES_fill_tcp_data_p(buf,dat_p,PSTR("<h1>200 OK</h1>"));
      goto SENDTCP;
    }
    // just one web page in the "root directory" of the web server
    if (strncmp("/ ",(char *)&(buf[dat_p+4]),2)==0){
      dat_p=print_webpage(buf);
      goto SENDTCP;
    }
    else{
      dat_p=es.ES_fill_tcp_data_p(buf,0,PSTR("HTTP/1.0 401 Unauthorized\r\nContent-Type: text/html\r\n\r\n<h1>401 Unauthorized</h1>"));
      goto SENDTCP;
    }
SENDTCP:
    es.ES_www_server_reply(buf,dat_p); // send web page data
    // tcp port 80 end

  }

}


