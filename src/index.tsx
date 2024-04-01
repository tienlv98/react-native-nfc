import { NativeModules, Platform } from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-nfc' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const Nfc = NativeModules.Nfc
  ? NativeModules.Nfc
  : new Proxy(
    {},
    {
      get() {
        throw new Error(LINKING_ERROR);
      },
    }
  );

export function gift(): Promise<number> {
  return Nfc.gift();
}

export function read(): Promise<string[]> {
  return Nfc.read();
}

export function write(data: number[]) {
  return Nfc.write(data);
}