# solidity_auction
一个简单的拍卖行

## 实现功能
拍卖行设置起拍价格，拍卖时间
```solidity
putOncommodity(uint256 pid,uint256 price,uint256 time)
```
### 出价人出价
```solidity
bid(uint256 pid)
```
###拍卖时间结束后拍卖行结束拍卖
```solidity
auctionEnd(uint256 pid)
```
### 获取商品信息
getName(uint256 pid)
### 获取商品状态
getStatus(uint256 pid)
### 获取商品起拍价格
getPrice(uint256 pid)
### 获取商品当前最高价
getMaxPrice(uint256 pid)
### 获取商品归属人
getOwner(uint256 pid)
### 获取商品拍卖时间
getAllTimestamp(uint256 pid)
### 获取当前出价人数
getBidderNum(uint256 pid)
### 获取商品起拍时间
getStartTimestamp(uint256 pid)
### 获取商品出价剩余时间
getRemainderTimestamp(uint256 pid)
### 获取商品拍卖结束时间
getStopTimestamp(uint256 pid)
### 获取出价人当前在拍卖行的钱
getBid(uint256 pid)
### 出价人取回钱
withdraw(uint256 pid)
