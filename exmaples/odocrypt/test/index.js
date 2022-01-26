//////////////////////////////////////////////////////////////////////////////////
/*
 *  AtomMiner XCA200T FPGA projects
 *  ODOcrypt test script. Valid for ODO epoch 1642464000
 *  
 *  Copyright 2015-2022 AtomMiner <atom@atomminer.com>
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version. If not, see <http://www.gnu.org/licenses/>.
 *
 */ 
 //////////////////////////////////////////////////////////////////////////////////
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const colors = require('colors');
const usb = require('usb');

const ZeroBuff = Buffer.alloc(0);

var running = true;
var rl = readline.createInterface(process.stdin, process.stdout);

const msleep = ms => new Promise(resolve => setTimeout(resolve, ms));

const resetFPGA = async (dev) => {
	return new Promise((resolve, reject) => {
		dev.controlTransfer(0x77, 0x14, 0, 0, ZeroBuff, (err, dat) => {
			if(err) reject(err);
			else resolve();
		});
	});
}

const sendData = async (ep, data) => {
	return new Promise((resolve,reject) => {
		ep.transfer(data, (err, num) => {
			if(err) reject(err);
			else resolve(num);
		});
	});
}

const programFPGA = async (dev) => {
	const fname = path.join(__dirname, 'atomminer_odocrypt.bin');
	const bs = fs.readFileSync(fname);
	var msg = '';

	if(!bs) {
		msg = `Can't read bitstream file: ${fname}`;
		console.log(msg)
		throw new Error(msg);
	}

	if(bs.length != 9730652) {
		msg = `bitstream file size mismatch. Compressed bitstreams are not supported: ${fname}`;
		console.log(msg)
		throw new Error(msg);
	}
	var magic = bs.readUInt32LE(48) >>> 0;
	if(magic != 0x5599aa66) {
		console.log('Bitstreams must be provided in SMAP32 format without header. Aborting'.error);
		throw new Error('Bistream format is not supported');
	}

	const iface = dev.interfaces[dev.interfaces.length - 1];
	iface.claim();
	const ep = iface.endpoint(0x01);

	await sendData(ep, ZeroBuff);

	var len = bs.length;
	var i = 0;
	while (i < len) {
		var buf = bs.slice(i, i += 32768);
		await sendData(ep, buf).finally(() => {buf = null});
	}

	await sendData(ep, ZeroBuff);

	await msleep(50);
	const mode = await getDeviceMode(dev);
	if(mode != 0x16) throw new Error('Failed to configure FPGA');
}

const getDeviceMode = (dev) => {
	return new Promise((resolve,reject) => {
		dev.controlTransfer(0xb2, 0x05, 0, 0, 1, (err, dat) => {
			if(err || !dat) reject(err || 'Device error');
			else resolve(dat.readUInt8(0));
		});
	});
}

const sendTestBlock = async (dev) => {
	const block = Buffer.from('00000000020e002094e2d4af77e77c3fe16e9d67f2c676b41e6c20e59a9bf4c293effd10313f71f83112152a14ff21b7764717446f52e4051a1db8e570f001c33fcb396b25c42fc71d79f161ed33591a1000000000009aaa000000000000000000000000000000000000000000000000', 'hex');
	return new Promise((resolve,reject) => {
		dev.controlTransfer(0x77, 0xf2, 0, 0, block, (err) => {
			console.log('Test block sent to device');
			if(err) reject(err);
			else resolve();
		});
	});
}

const readStatus = async (dev) => {
	var buf = await new Promise((resolve,reject) => {
		dev.controlTransfer(0xb2, 0x06, 0, 0, 128, (err, data) => {
			if(err) reject(err);
			else resolve(data);
		});
	});
	if(!buf) throw new Error('Failed to read device status')
	
	var temp = ((0xffff & (buf.readUInt32LE(40) >> 4)) * 503.975 / 4096) - 273.15;
	var vcc = 4.57763671875e-05 * (0xffff & (buf.readUInt32LE(44)));

	console.log(`   Device T: ${temp.toFixed(2)}C VCC: ${vcc.toFixed(3)}V`);
	return buf.readUInt32LE(56) >>> 0;
}

(async () =>{
	console.log('This is test application for ODO bistream on AM01 FPGA miner. ');
	console.log('Please make sure to only load AM01 bitstreams. Bistreams made ');
	console.log('for any other boards/devices can fry your device.')
	console.log('--------------------------------------------------------------');
	console.log('                   NEVER EVER:                                '.red);
	console.log('- Load bistreams made for any equipment other than AM01'.red);
	console.log('- Send random data instead of valid bitsreams.'.red);
	console.log(`
By continuing (i.e. by using unsigned bitstreams) you agree to
AtomMiner Terms of Service. You agree that you are solely 
responsible for (and that AtomMiner has no responsibility to you 
or to any third party for) any breach and/or damages direct or 
indirect of your actions.
`);

	await new Promise(resolve => {
		rl.question("Continue? yes/[no]: ", answer => {
			if(answer !== "yes") {
					console.log ("Terms are not accepted. Aborting");
					process.exit(1);
			}
			resolve();
		});
	});

	// find connected AM01
	const device = usb.findByIds(0x16d0, 0x0e1e);
	if(!device) {
		console.error('Warning! No connected AM01 devices discovered. Aborting'.yellow);
		process.exit(1);
	}

	// open device
	device.open(true);

	// reset configuration
	await resetFPGA(device);
	await msleep(50);

	// config FPGA
	var tmStart = +new Date();
	await programFPGA(device);

	// send test block
	await msleep(70);
	await sendTestBlock(device);

	// read device status while it is busy
	var nonce = 0;
	var finish = false;
	// 15 seconds should be more than enough to find correct nonce
	setTimeout(() => {
		console.log('Timeout'.yellow)
		finish = 5;
	}, 15000);
	do {
		await msleep(500);
		nonce = await readStatus(device);
	} while(!(nonce || finish));

	var tmEnd = +new Date();

	// compare AM01 response to expected value
	if(nonce == 0x040aad0e) {
		console.log(`Received correct nonce from device ${nonce.toString(16)}`.green)
	}
	else {
		console.log(`Received incorrect nonce from device ${nonce.toString(16)}`.yellow)
	}

	// hashrate nonces / calc_time
	console.log(`Estimated hashrate: ${(nonce/(tmEnd - tmStart) / 1000).toFixed(2)}MH/s`);
	console.log();

	device.close();
	running = false;
})().catch(e => {
	console.error(e);
	running = false;
});

const checkExit = () => {
	if(running) {
		setTimeout(checkExit, 250);
	}
	else {
		process.exit(0);
	}
}

setTimeout(checkExit, 250)