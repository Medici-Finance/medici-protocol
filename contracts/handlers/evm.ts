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

function checkDeploy(chain: string) {
  let deployInfo;
  try {
    deployInfo = JSON.parse(fs.readFileSync(`./deployinfo/${chain}.deploy.json`).toString());
  } catch (e) {
    throw new Error(`${chain} is not deployed yet`);
  }
  return deployInfo;
}

/**
 * 1. Deploy on chain core contract
 * @param chain The network to deploy
 */
export async function deploy(chain: string, core: boolean) {
  const network = config.testnet[chain];

  const scriptFn = core ? 'deployCore' : chain === 'goerli' ? 'deployPeripheryGeorli' : 'deployPeripheryFuji';

  const script = `forge script test/Medici.s.sol:Medici --sig "${scriptFn}()" --rpc-url ${network.rpc} --broadcast -vvv`;

  const { stdout, stderr } = await exec(script);

  if (stderr) {
    throw new Error(stderr);
  }

  let deploymentAddress;
  if (stdout) {
    let tx = JSON.parse(
      fs.readFileSync(`./broadcast/Medici.s.sol/${network.chainId}/${scriptFn}-latest.json`).toString()
    ).transactions;
    for (const t of tx) {
      if (t.contractName?.includes('MediciCore') || t.contractName?.includes('Periphery')) {
        deploymentAddress = t.contractAddress;
      }
    }
    console.log('contracts at ', deploymentAddress);
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

export async function verifyContracts(chain: string, node: boolean) {
  const network = config.testnet[chain];

  let srcDeploymentInfo;

  try {
    srcDeploymentInfo = JSON.parse(fs.readFileSync(`./deployinfo/${chain}.deploy.json`).toString());
  } catch (e) {
    throw new Error(`${chain} is not deployed yet`);
  }

  // TODO - verify core
  // TODO - verify periphery
  const script = `forge verify-contract ${srcDeploymentInfo.address} src/periphery/Periphery.sol:Periphery ${process.env.ETHERSCAN_API_KEY} --chain-id 5`;

  const { stdout, stderr } = await exec(script);

  if (stderr) {
    throw new Error(stderr);
  }

  if (stdout) {
    console.log(stdout);
  }
}

export async function registerApp(src: string, target: string, isCore: boolean) {
  const srcNetwork = config.testnet[src];
  const targetNetwork = config.testnet[target];
  let srcDeploymentInfo = checkDeploy(src);
  let targetDeploymentInfo = checkDeploy(target);
  let targetEmitter;

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
  const signer = new ethers.Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(srcNetwork.rpc)
  );

  if (isCore) {
    const core = new ethers.Contract(
      srcDeploymentInfo.address,
      JSON.parse(fs.readFileSync('./out/MediciCore.sol/MediciCore.json').toString()).abi,
      signer
    );

    const tx = await core.registerChain(targetNetwork.wormholeChainId, emitterBuffer);
  } else {
    const periphery = new ethers.Contract(
      srcDeploymentInfo.address,
      JSON.parse(fs.readFileSync('./out/Periphery.sol/Periphery.json').toString()).abi,
      signer
    );

    const tx = await periphery.registerCore(targetNetwork.wormholeChainId, emitterBuffer, {
      gasLimit: 1000000,
    });
  }
  console.log(`Registered ${target} application on ${src}`);
}

export async function authenticate() {}

export async function requestLoan(chain: string, loanAmt: bigint, apr: bigint, tenor: bigint) {
  const srcNetwork = config.testnet[chain];
  let srcDeploymentInfo = checkDeploy(chain);

  const signer = new ethers.Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(srcNetwork.rpc)
  );

  const periphery = new ethers.Contract(
    srcDeploymentInfo.address,
    JSON.parse(fs.readFileSync('./out/Periphery.sol/Periphery.json').toString()).abi,
    signer
  );

  const tx = await (
    await periphery.request(loanAmt, apr, tenor, {
      gasLimit: 1000000,
    })
  ).wait();

  const seq = parseSequenceFromLogEth(tx, srcNetwork['bridgeAddress']);
  console.log('Sequence', seq);
  const emitterAddr = getEmitterAddressEth(srcDeploymentInfo['address']);
  console.log('Emitter', emitterAddr);

  await new Promise((r) => setTimeout(r, 5000)); // wait for the guardian to pick up the loan request

  console.log(
    'Searching for: ',
    `${config.wormhole.restAddress}/v1/signed_vaa/${srcNetwork.wormholeChainId}/${emitterAddr}/${seq}`
  );

  const vaaBytes = await (
    await fetch(`${config.wormhole.restAddress}/v1/signed_vaa/${srcNetwork.wormholeChainId}/${emitterAddr}/${seq}`)
  ).json();

  if (!vaaBytes['vaaBytes']) {
    throw new Error('VAA not found!');
  }

  if (!srcDeploymentInfo['vaas']) {
    srcDeploymentInfo['vaas'] = [vaaBytes['vaaBytes']];
  } else {
    srcDeploymentInfo['vaas'].push(vaaBytes['vaaBytes']);
  }
  fs.writeFileSync(`./deployinfo/${chain}.deploy.json`, JSON.stringify(srcDeploymentInfo, null, 4));
  return vaaBytes['vaaBytes'];
}

export async function submitVaa(src: string, target: string, idx: string) {
  const targetNetwork = config.testnet[target];
  let srcDeploymentInfo = checkDeploy(src);
  console.log('Target - ', target);
  let targetDeploymentInfo = checkDeploy(target);

  const vaa = isNaN(parseInt(idx)) ? srcDeploymentInfo.vaas.pop() : srcDeploymentInfo.vaas[parseInt(idx)];

  // testing
  console.log('testing - ', Buffer.from(vaa, 'base64').toString('hex'));

  const signer = new ethers.Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(targetNetwork.rpc)
  );
  const core = new ethers.Contract(
    targetDeploymentInfo.address,
    JSON.parse(fs.readFileSync('./out/MediciCore.sol/MediciCore.json').toString()).abi,
    signer
  );
  const tx = await core.initLoan(Buffer.from(vaa, 'base64'), {
    gasLimit: 2100000,
  });
  console.log(tx);
  return tx;
}

export async function getOpenLoans(core: string) {
  const coreNetwork = config.testnet[core];
  let coreDeploymentInfo = checkDeploy(core);

  const signer = new ethers.Wallet(process.env.PRIVATE_KEY).connect(
    new ethers.providers.JsonRpcProvider(coreNetwork.rpc)
  );

  const periphery = new ethers.Contract(
    coreDeploymentInfo.address,
    JSON.parse(fs.readFileSync('./out/MediciCore.sol/MediciCore.json').toString()).abi,
    signer
  );

  return await periphery.getOpenLoans();
}

export async function initLend() {}
