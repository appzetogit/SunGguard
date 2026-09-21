import Bull from "bull";
import {
  getRedisOptionsForBull,
  isBullMQEnabled,
  createBullRedisClient,
} from "../config/redis.js";

const queueSettings = {
  stalledInterval: 30000,
  maxStalledCount: 2,
};

function createNoopQueue() {
  return {
    add: async () => ({}),
    getJob: async () => null,
    process: () => {},
    on: () => {},
    close: async () => {},
  };
}

const queuesEnabled = isBullMQEnabled();
const redisOpts = queuesEnabled ? getRedisOptionsForBull() : null;

export const sellerTimeoutQueue = queuesEnabled
  ? new Bull("seller-timeout", {
      redis: redisOpts,
      createClient: createBullRedisClient,
      settings: queueSettings,
    })
  : createNoopQueue();

export const deliveryTimeoutQueue = queuesEnabled
  ? new Bull("delivery-timeout", {
      redis: redisOpts,
      createClient: createBullRedisClient,
      settings: queueSettings,
    })
  : createNoopQueue();

export const returnPickupTimeoutQueue = queuesEnabled
  ? new Bull("return-pickup-timeout", {
      redis: redisOpts,
      createClient: createBullRedisClient,
      settings: queueSettings,
    })
  : createNoopQueue();

export const JOB_NAMES = {
  SELLER_TIMEOUT: "seller-timeout",
  DELIVERY_TIMEOUT: "delivery-timeout",
  RETURN_PICKUP_TIMEOUT: "return-pickup-timeout",
};
