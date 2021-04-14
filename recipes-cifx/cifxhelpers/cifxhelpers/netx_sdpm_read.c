#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/ioctl.h>
#include <linux/spi/spidev.h>

static uint32_t speed = 500000;
static const char *device = "/dev/spidev1.0";
static uint8_t bits = 8;
static uint32_t mode;
static uint32_t delay = 0;
static uint32_t offset = 0;
static uint32_t length = 4;

static void pabort(const char *s)
{
	perror(s);
	abort();
}

static void hex_dump(const void *src, size_t length)
{
	int i = 0;
	const unsigned char *address = src;

	while (length-- > 0) {
		printf("%02X", *address++);
	}
}

static void sdpm_read(int fd, uint32_t off, uint32_t len, uint8_t *buffer)
{
	int ret;
	int out_fd;
	uint32_t transfer_len = len + 4;
	uint8_t *tmp_buf = malloc(transfer_len + 4);

	struct spi_ioc_transfer tr = {
		.tx_buf = (unsigned long)tmp_buf,
		.rx_buf = (unsigned long)tmp_buf,
		.len = transfer_len,
		.delay_usecs = delay,
		.speed_hz = speed,
		.bits_per_word = bits,
	};

	memset(tmp_buf, 0, transfer_len);
	tmp_buf[0] = 0x80 | ((off & 0x7F0000) >> 16);
	tmp_buf[1] = (off & 0xFF00) >> 8;
	tmp_buf[2] = off & 0xFF;
	tmp_buf[3] = 0;

	ret = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
	if (ret < 1)
		pabort("can't send spi message");

	memcpy(buffer, tmp_buf + 4, len);
}

static void print_usage(const char *prog)
{
	printf("Usage: %s [-DsbdlHOLC3]\n", prog);
	puts("  -D --device   device to use (default /dev/spidev1.1)\n"
	     "  -s --speed    max speed (Hz)\n"
	     "  -d --delay    delay (usec)\n"
	     "  -H --cpha     clock phase\n"
	     "  -O --cpol     clock polarity\n"
	     "  -o --offset   byte offset to read\n"
	     "  -l --length   bytes to read\n");
	exit(1);
}

static void parse_opts(int argc, char *argv[])
{
	while (1) {
		static const struct option lopts[] = {
			{ "device",  1, 0, 'D' },
			{ "delay",   1, 0, 'd' },
			{ "speed",   1, 0, 's' },
			{ "cpha",    0, 0, 'H' },
			{ "cpol",    0, 0, 'O' },
			{ "offset",  1, 0, 'o' },
			{ "length",  1, 0, 'l' },
			{ NULL, 0, 0, 0 },
		};
		int c;

		c = getopt_long(argc, argv, "D:d:s:l:o:HO",
				lopts, NULL);

		if (c == -1)
			break;

		switch (c) {
		case 'D':
			device = optarg;
			break;
		case 'd':
			delay = atoi(optarg);
			break;
		case 's':
			speed = atoi(optarg);
			break;
		case 'H':
			mode |= SPI_CPHA;
			break;
		case 'O':
			mode |= SPI_CPOL;
			break;
		case 'o':
			offset = atoi(optarg);
			break;
		case 'l':
			length = atoi(optarg);
			break;
		default:
			print_usage(argv[0]);
			break;
		}
	}
}

int main(int argc, char *argv[])
{
	int ret = 0;
	int fd;
	uint8_t dummy_read[4];
	uint8_t *buffer;

	parse_opts(argc, argv);

	fd = open(device, O_RDWR);
	if (fd < 0)
		pabort("can't open device");

	/*
	 * spi mode
	 */
	ret = ioctl(fd, SPI_IOC_WR_MODE32, &mode);
	if (ret == -1)
		pabort("can't set spi mode");

	ret = ioctl(fd, SPI_IOC_RD_MODE32, &mode);
	if (ret == -1)
		pabort("can't get spi mode");

	/*
	 * bits per word
	 */
	ret = ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits);
	if (ret == -1)
		pabort("can't set bits per word");

	ret = ioctl(fd, SPI_IOC_RD_BITS_PER_WORD, &bits);
	if (ret == -1)
		pabort("can't get bits per word");

	/*
	 * max speed hz
	 */
	ret = ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);
	if (ret == -1)
		pabort("can't set max speed hz");

	ret = ioctl(fd, SPI_IOC_RD_MAX_SPEED_HZ, &speed);
	if (ret == -1)
		pabort("can't get max speed hz");

	// Perform 2 dummy reads to make sure netX is synced
	sdpm_read(fd, 0xfffc, sizeof(dummy_read), dummy_read);
	sdpm_read(fd, 0xfffc, sizeof(dummy_read), dummy_read);

	buffer = malloc(length);
	memset(buffer, 0, length);

	sdpm_read(fd, offset, length, buffer);

	hex_dump(buffer, length);

	free(buffer);
	close(fd);

	return ret;
}
