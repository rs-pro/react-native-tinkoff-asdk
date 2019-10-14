
import { NativeModules } from 'react-native';

const { RNTinkoffAsdk } = NativeModules;

console.log("tinkoff native module:", RNTinkoffAsdk)

export default RNTinkoffAsdk;
