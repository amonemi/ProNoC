/*
 * Copyright (c) 2016, Matt Redfearn
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stddef.h>
#include <stdarg.h>

#ifdef TEST
#include <stdio.h>
#endif /* TEST */

static void simple_outputchar(char **str, char c)
{
	if (str) {
		**str = c;
		++(*str);
	} else {
		outbyte(c);
	}
}

enum flags {
	PAD_ZERO	= 1,
	PAD_RIGHT	= 2,
};

static int prints(char **out, const char *string, int width, int flags)
{
	int pc = 0, padchar = ' ';

	if (width > 0) {
		int len = 0;
		const char *ptr;
		for (ptr = string; *ptr; ++ptr) ++len;
		if (len >= width) width = 0;
		else width -= len;
		if (flags & PAD_ZERO)
			padchar = '0';
	}
	if (!(flags & PAD_RIGHT)) {
		for ( ; width > 0; --width) {
			simple_outputchar(out, padchar);
			++pc;
		}
	}
	for ( ; *string ; ++string) {
		simple_outputchar(out, *string);
		++pc;
	}
	for ( ; width > 0; --width) {
		simple_outputchar(out, padchar);
		++pc;
	}

	return pc;
}

#define PRINT_BUF_LEN 64

static int simple_outputi(char **out, int i, int base, int sign, int width, int flags, int letbase)
{
	char print_buf[PRINT_BUF_LEN];
	char *s;
	int t, neg = 0, pc = 0;
	unsigned int u = i;

	if (i == 0) {
		print_buf[0] = '0';
		print_buf[1] = '\0';
		return prints(out, print_buf, width, flags);
	}

	if (sign && base == 10 && i < 0) {
		neg = 1;
		u = -i;
	}

	s = print_buf + PRINT_BUF_LEN-1;
	*s = '\0';

	while (u) {
		t = u % base;
		if( t >= 10 )
			t += letbase - '0' - 10;
		*--s = t + '0';
		u /= base;
	}

	if (neg) {
		if( width && (flags & PAD_ZERO) ) {
			simple_outputchar (out, '-');
			++pc;
			--width;
		}
		else {
			*--s = '-';
		}
	}

	return pc + prints (out, s, width, flags);
}


static int simple_vsprintf(char **out, char *format, va_list ap)
{
	int width, flags;
	int pc = 0;
	char scr[2];
	union {
		char c;
		char *s;
		int i;
		unsigned int u;
		void *p;
	} u;

	for (; *format != 0; ++format) {
		if (*format == '%') {
			++format;
			width = flags = 0;
			if (*format == '\0')
				break;
			if (*format == '%')
				goto out;
			if (*format == '-') {
				++format;
				flags = PAD_RIGHT;
			}
			while (*format == '0') {
				++format;
				flags |= PAD_ZERO;
			}
			if (*format == '*') {
				width = va_arg(ap, int);
				format++;
			} else {
				for ( ; *format >= '0' && *format <= '9'; ++format) {
					width *= 10;
					width += *format - '0';
				}
			}
			switch (*format) {
				case('d'):
					u.i = va_arg(ap, int);
					pc += simple_outputi(out, u.i, 10, 1, width, flags, 'a');
					break;

				case('u'):
					u.u = va_arg(ap, unsigned int);
					pc += simple_outputi(out, u.u, 10, 0, width, flags, 'a');
					break;

				case('x'):
					u.u = va_arg(ap, unsigned int);
					pc += simple_outputi(out, u.u, 16, 0, width, flags, 'a');
					break;

				case('X'):
					u.u = va_arg(ap, unsigned int);
					pc += simple_outputi(out, u.u, 16, 0, width, flags, 'A');
					break;

				case('c'):
					u.c = va_arg(ap, int);
					scr[0] = u.c;
					scr[1] = '\0';
					pc += prints(out, scr, width, flags);
					break;

				case('s'):
					u.s = va_arg(ap, char *);
					pc += prints(out, u.s ? u.s : "(null)", width, flags);
					break;
				default:
					break;
			}
		}
		else {
out:
			simple_outputchar (out, *format);
			++pc;
		}
	}
	if (out) **out = '\0';
	return pc;
}

int simple_printf(char *fmt, ...)
{
	va_list ap;
	int r;

	va_start(ap, fmt);
	r = simple_vsprintf(NULL, fmt, ap);
	va_end(ap);

	return r;
}

int simple_sprintf(char *buf, char *fmt, ...)
{
	va_list ap;
	int r;

	va_start(ap, fmt);
	r = simple_vsprintf(&buf, fmt, ap);
	va_end(ap);

	return r;
}


#ifdef TEST

#define printf simple_printf
#define sprintf simple_sprintf

int main(int argc, char *argv[])
{
	static char shortstr[] = "Test";
	char buf[256];

	printf("percent:                \"%%\"\n");
	printf("bad format:             \"%z\"\n");
	printf("\n");
	printf("decimal:                \"%d\"\n", 12345);
	printf("decimal negative:       \"%d\"\n", -2345);
	printf("\n");
	printf("unsigned:               \"%u\"\n", 12345);
	printf("unsigned negative:      \"%u\"\n", -2345);
	printf("\n");
	printf("hex:                    \"%x\"\n", 0x12345);
	printf("hex negative:           \"%x\"\n", -0x12345);
	printf("\n");
	printf("long decimal:           \"%ld\"\n", 123456L);
	printf("long decimal negative:  \"%ld\"\n", -23456L);
	printf("\n");
	printf("long unsigned:          \"%lu\"\n", 123456L);
	printf("long unsigned negative: \"%lu\"\n", -123456L);
	printf("\n");
	printf("long hex:               \"%x\"\n", 0x12345L);
	printf("long hex negative:      \"%x\"\n", -0x12345L);
	printf("\n");
	printf("zero-padded LD:         \"%010ld\"\n", 123456);
	printf("zero-padded LDN:        \"%010ld\"\n", -123456);
	printf("left-adjusted ZLDN:     \"%-010ld\"\n", -123456);
	printf("space-padded LDN:       \"%10ld\"\n", -123456);
	printf("left-adjusted SLDN:     \"%-10ld\"\n", -123456);
	printf("\n");
	printf("variable pad width:     \"%0*d\"\n", 15, -2345);
	printf("\n");
	printf("char:                   \"%c%c%c%c\"\n", 'T', 'e', 's', 't');
	printf("\n");
	printf("zero-padded string:     \"%010s\"\n", shortstr);
	printf("left-adjusted Z string: \"%-010s\"\n", shortstr);
	printf("space-padded string:    \"%10s\"\n", shortstr);
	printf("left-adjusted S string: \"%-10s\"\n", shortstr);
	printf("null string:            \"%s\"\n", (char *)NULL);

	sprintf(buf, "decimal:\t\"%d\"\n", -2345);
	printf("sprintf: %s", buf);
}
#endif /* TEST */
