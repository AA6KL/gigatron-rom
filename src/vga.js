'use strict';

/* exported Vga */

const VSYNC = 0x80;
const HSYNC = 0x40;

/** Vga */
class Vga {
	/** Create a new Vga
	 * @param {Gigatron} cpu
	 * @param {object} options
	 */
	constructor(canvas, cpu, options) {
		this.canvas = canvas;
		this.canvas.width = options.horizontal.visible;
		this.canvas.height = options.vertical.visible;
		this.ctx = canvas.getContext('2d');
		this.imageData = this.ctx.getImageData(0, 0, canvas.width, canvas.height);
		this.pixels = this.imageData.data;
		this.cpu = cpu;
		this.row = 0;
		this.minRow = options.vertical.backPorch;
		this.maxRow = this.minRow + options.vertical.visible;
		this.col = 0;
		this.minCol = options.horizontal.backPorch;
		this.maxCol = this.minCol + options.horizontal.visible;
		this.pixel = 0;
		this.out = 0;
		// turn all pixels black with full alpha
		for (let i = 0; i < this.pixels.length; i++) {
			this.pixels[i] = (i % 4) == 3 ? 255 : 0;
		}
		this.render();
	}

	render() {
		this.ctx.putImageData(this.imageData, 0, 0);
	}

	/** advance simulation by one tick */
	tick() {
		let out = this.cpu.out;
		let falling = this.out & ~out;
		this.out = out;

		if (falling & VSYNC) {
			this.row = 0;
			this.pixel = 0;
			this.ctx.putImageData(this.imageData, 0, 0); // calling render slows down critical loop
		}

		if (falling & HSYNC) {
			this.col = 0;
			this.row++;
		}

		if ((out & (VSYNC|HSYNC)) != (VSYNC|HSYNC)) {
			// blanking interval
			return;
		}

		if ((this.row >= this.minRow && this.row < this.maxRow) &&
  			(this.col >= this.minCol && this.col < this.maxCol)) {
			let pixels = this.pixels;
			let pixel = this.pixel;
			let r = (out << 6) & 0xc0;
			let g = (out << 4) & 0xc0;
			let b = (out << 2) & 0xc0;

			for (let i = 0; i < 4; i++) {
				pixels[pixel++] = r;
				pixels[pixel++] = g;
				pixels[pixel++] = b;
				pixel++;
			}

			this.pixel = pixel;
		}

		this.col += 4;
	}
}
