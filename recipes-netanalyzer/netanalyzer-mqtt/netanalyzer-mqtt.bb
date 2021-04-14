SUMMARY="netANALYZER sample application"
HOMEPAGE="http://www.hilscher.com"
LICENSE="CLOSED"

SRC_URI = "file://netanalyzer_mqtt.c \
           file://netanalyzer_mqtt_wolfmqtt.c \
"

S="${WORKDIR}"

DEPENDS="libnetana paho-mqtt-c wolfmqtt jansson"
RDEPENDS_${PN} = "mosquitto"

do_configure() {
    :
}

do_compile() {
    ${CC} ${LDFLAGS} netanalyzer_mqtt.c -o ${B}/netanalyzer_mqtt -I=/usr/include/netana -lnetana -lpaho-mqtt3c -lpthread -ljansson
    ${CC} ${LDFLAGS} netanalyzer_mqtt_wolfmqtt.c -o ${B}/netanalyzer_mqtt_wolfmqtt -I=/usr/include/netana -lnetana -lwolfmqtt -lpthread
}

do_install() {
    install -d ${D}/opt/netanalyzer
    install ${B}/netanalyzer_mqtt ${D}/opt/netanalyzer
    install ${B}/netanalyzer_mqtt_wolfmqtt ${D}/opt/netanalyzer
}

FILES_${PN} = "/opt"
