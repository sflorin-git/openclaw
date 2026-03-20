import { isProviderPluginExpectedForEnv } from './src/config/plugin-auto-enable.ts';

// Mock environment
const mockEnv = {
    OPENROUTER_API_KEY: 'test-key'
};

const expected = isProviderPluginExpectedForEnv('openrouter', mockEnv);
console.log('Is openrouter expected with key?', expected);

const notExpected = isProviderPluginExpectedForEnv('openrouter', {});
console.log('Is openrouter expected without key?', notExpected);
