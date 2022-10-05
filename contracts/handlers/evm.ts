import fs from 'fs';
import {
  attestFromEth,
  createWrappedOnEth,
  getEmitterAddressEth,
  getEmitterAddressSolana,
  getForeignAssetEth,
  parseSequenceFromLogEth,
  redeemOnEth,
  setDefaultWasm,
  transferFromEthNative,
  tryNativeToUint8Array,
} from '@certusone/wormhole-sdk';
import * as ethers from 'ethers';
import { promisify } from 'util';
import * as dotenv from 'dotenv';

dotenv.config();

const exec = promisify(require('child_process').exec);
const config = JSON.parse(fs.readFileSync('./xdapp.config.json').toString());

// let ABI = {};
// try {
//   ABI = JSON.parse(fs.readFileSync('./chains/evm/out/MediciCore.sol/MediciCore.json').toString()).abi;
// } catch (e) {
//   // fail silenty
//   // The only time this fails is when deploy hasn't been called, in which case, this isn't needed
// }

// `forge script test/Medici.s.sol:Medici --legacy --rpc-url ${} -g 1000 --json`,

// `forge build && forge create test/Medici.s.sol:Medici --legacy --rpc-url ${network.rpc} --broadcast -vvv`,
// `forge build && forge create --legacy --rpc-url ${network.rpc} --private-key ${network.privateKey} test/LocalConfig.sol:LocalConfig src/core/MediciCore.sol:MediciCore && exit`

/**
 * 1. Deploy on chain core contract
 * @param chain The network to deploy
 */
export async function deploy(chain: string, core: boolean) {
  const network = config.testnet[chain];
  const scriptFn = core ? 'deployCore' : 'deployPeriphery';

  const script = `forge script test/Medici.s.sol:Medici --sig "${scriptFn}()" --rpc-url ${network.rpc} --broadcast -vvv`;

  const { stdout, stderr } = await exec(script);

  if (stderr) {
    throw new Error(stderr);
  }

  let deploymentAddress;
  if (stdout) {
    let tx = JSON.parse(fs.readFileSync('./broadcast/Medici.s.sol/5/deployCore-latest.json').toString()).transactions;
    for (const t of tx) {
      if (t.contractName === 'MediciCore') {
        deploymentAddress = t.contractAddress;
      }
    }
    const emittedVAAs = []; //Resets the emittedVAAs

    fs.writeFileSync(
      `./deployinfo/${chain}.deploy.json`,
      JSON.stringify(
        {
          address: deploymentAddress,
          vaas: emittedVAAs,
        },
        null,
        4
      )
    );
  }
}

export async function registerApp(src: string, target: string) {
  const srcNetwork = config.testnet[src];
  const targetNetwork = config.testnet[target];
  let srcDeploymentInfo;
  let targetDeploymentInfo;
  let targetEmitter;

  try {
    srcDeploymentInfo = JSON.parse(fs.readFileSync(`./deployinfo/${src}.deploy.json`).toString());
  } catch (e) {
    throw new Error(`${src} is not deployed yet`);
  }

  try {
    targetDeploymentInfo = JSON.parse(fs.readFileSync(`./deployinfo/${target}.deploy.json`).toString());
  } catch (e) {
    throw new Error(`${target} is not deployed yet`);
  }

  switch (targetNetwork['type']) {
    case 'evm':
      targetEmitter = getEmitterAddressEth(targetDeploymentInfo['address']);
      break;
    case 'solana':
      //   setDefaultWasm('node'); // *sigh*
      //   targetEmitter = await getEmitterAddressSolana(targetDeploymentInfo['address']);
      break;
  }

  console.log(targetDeploymentInfo['address']);
  const emitterBuffer = Buffer.from(targetEmitter, 'hex');
  console.log('this works');
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(srcNetwork.rpc)
  );
  console.log('this also works');
  const core = new ethers.Contract(
    srcDeploymentInfo.address,
    JSON.parse(fs.readFileSync('./out/MediciCore.sol/MediciCore.json').toString()).abi,
    signer
  );

  const tx = await core.registerChain(targetNetwork.wormholeChainId, emitterBuffer);
  console.log(`Registered ${target} application on ${src}`);
}

export async function authenticate() {}

export async function loanRequest() {}
