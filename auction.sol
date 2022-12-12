// SPDX-License-Identifier: SimPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract auction {

    // 拍卖行
    address payable auctionHouse;

    struct commodity {
        string name;
        //状态
        string state;
        //起拍价
        uint256 price;
        //最高价
        uint256 maxPrice;
        //当前拥有者
        address highestBidder;
        //拍卖时间
        uint256 time;
        //当前出价人数
        uint256 bidderNum;
        //出价人地址对应的出价
        mapping(address => uint256) pendingReturns;
        //起拍时间戳
        uint256 setTime;
    }
    
    //商品列表
    mapping(uint256 => commodity) public commoditys;
    //状态列表
    mapping(uint256 => string) states;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(address _ower) {
        //设置拍卖行
        auctionHouse = payable(_ower);

        states[0] = "Not listed";
        states[1] = "On sale";
        states[2] = "Had sold";

        commoditys[0].name = unicode"手机";
        commoditys[0].state = states[0];
        commoditys[0].price = 100;
        commoditys[0].highestBidder = _ower;
        commoditys[0].time = 10;

        commoditys[1].name = unicode"电脑";
        commoditys[1].state = states[0];
        commoditys[1].price = 100;
        commoditys[1].highestBidder = _ower;
        commoditys[1].time = 10;

        commoditys[2].name = unicode"平板";
        commoditys[2].state = states[0];
        commoditys[2].price = 100;
        commoditys[2].highestBidder = _ower;
        commoditys[2].time = 10;        
    }
    //身份验证
    modifier notAuctionHouse(){
        require(msg.sender == auctionHouse, "You don't have permissions");
        _;
    }

    //上架商品并设置起拍价格，拍卖时间
    function putOncommodity(uint256 pid,uint256 price,uint256 time) public notAuctionHouse returns(bool) {
        //检查状态
        require(keccak256(abi.encodePacked(commoditys[pid].state)) == keccak256(abi.encodePacked(states[0])) , "This item is listed or sold");
        //检查价格
        require(price >= 100 , "The starting price must not be less than 100xuper");
        //检查拍卖时间
        require(time <= 10 , "The auction time is up to 10 minutes");
        //设置时间
        commoditys[pid].time = time;
        //设置当前拥有者为拍卖行
        commoditys[pid].highestBidder = auctionHouse;
        //设置状态为售卖中
        commoditys[pid].state = states[1];
        // 设置起拍价格
        commoditys[pid].price = price;
        // 起拍价格为初始最高出价
        commoditys[pid].maxPrice = price;
        //设置起拍时间戳
        commoditys[pid].setTime = block.timestamp;
        return true;
    }

    // 出价
    function bid(uint256 pid) public payable returns(bool){
        // 能否继续叫价
        require(verifyBid(pid), "auction error: the item had sold");
        // 状态验证
        require(keccak256(abi.encodePacked(commoditys[pid].state)) == keccak256(abi.encodePacked(states[1])) , "auction error: this item cannot be bid");
        // 价格验证
        require(commoditys[pid].maxPrice < msg.value, "auction error: your price must more than the maxPrice");
        //检查余额是否满足要求
        require(msg.sender.balance >= msg.value , "auction error: Insufficient balance");
        //记录当前最高价与最高价地址
        if (commoditys[pid].maxPrice != 0) { 
            commoditys[pid].pendingReturns[commoditys[pid].highestBidder] += commoditys[pid].maxPrice;
        }
        commoditys[pid].highestBidder = msg.sender;
        commoditys[pid].maxPrice = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
        
        //记录出价人
        commoditys[pid].bidderNum++;
        
        
        return true;
    }
    // 能否继续叫价
    function verifyBid(uint256 pid) internal view returns(bool){
        return ( block.timestamp - commoditys[pid].setTime <  commoditys[pid].time*60 );
    }

    //结束拍卖
    function auctionEnd(uint256 pid) public notAuctionHouse returns(bool){
        require(block.timestamp - commoditys[pid].setTime >=  commoditys[pid].time*60 , unicode"拍卖未结束");
            // 需要停止 判断是否有人出价
            if(commoditys[pid].bidderNum != 0){
                // 状态更改为已出售
                commoditys[pid].state = states[2];
                emit AuctionEnded(commoditys[pid].highestBidder,commoditys[pid].maxPrice);
                payable(auctionHouse).transfer(commoditys[pid].maxPrice);
            }else{
                // 状态更改为未上架
                commoditys[pid].state = states[0];
            }
        return true;
    }

    //获取商品信息
    function getName(uint256 pid) public view returns(string memory){
        return commoditys[pid].name;
    }
    //获取商品状态
    function getStatus(uint256 pid) public view returns(string memory){
        return commoditys[pid].state;
    }
    // 获取商品起拍价格
    function getPrice(uint256 pid) public view returns(uint256){
        return commoditys[pid].price;
    }
    // 获取商品当前最高价
    function getMaxPrice(uint256 pid) public view returns(uint256){
        return commoditys[pid].maxPrice;
    }
    // 获取商品归属人
    function getOwner(uint256 pid) public view returns(address){
        return commoditys[pid].highestBidder;
    }
    // 获取商品拍卖时间
    function getAllTimestamp(uint256 pid) public view returns(uint256){
        return commoditys[pid].time;
    }
    // 获取当前出价人数
    function getBidderNum(uint256 pid) public view returns(uint256){
        return commoditys[pid].bidderNum;
    }
    //获取商品起拍时间
    function getStartTimestamp(uint256 pid) public view returns(string memory){
        require( keccak256(abi.encodePacked(commoditys[pid].state)) != keccak256(abi.encodePacked(states[0])) , unicode"商品未开始拍卖");
        return timestampToTime(commoditys[pid].setTime);
    }
    //获取商品出价剩余时间
    function getRemainderTimestamp(uint256 pid) public view returns(string memory){
        require( keccak256(abi.encodePacked(commoditys[pid].state)) != keccak256(abi.encodePacked(states[0])) , unicode"商品未开始拍卖");
        if(keccak256(abi.encodePacked(commoditys[pid].state)) != keccak256(abi.encodePacked(states[1]))){
            return "00:00";
        }
        uint256 time = commoditys[pid].time*60 + commoditys[pid].setTime - block.timestamp;
        return getRemainderTime(time);
    }
    //获取商品拍卖结束时间
    function getStopTimestamp(uint256 pid) public view returns(string memory){
        require( keccak256(abi.encodePacked(commoditys[pid].state)) != keccak256(abi.encodePacked(states[0])) , unicode"商品未开始拍卖");
        uint256 time = commoditys[pid].time*60 + commoditys[pid].setTime;
        return timestampToTime(time);
    }
    
    
    //获取出价人当前在拍卖行的钱
    function getBid(uint256 pid) public view returns(uint256){
        return commoditys[pid].pendingReturns[msg.sender];
    }
    
    //取回钱
    function withdraw(uint256 pid) external returns (bool) {
        //获取当前地址退回的数量
        uint amount = commoditys[pid].pendingReturns[msg.sender]; 
        if (amount > 0) {
            //重置为0
            commoditys[pid].pendingReturns[msg.sender] = 0;
            //如果返回失败,数量返回
            if (!payable(msg.sender).send(amount)) {
                commoditys[pid].pendingReturns[msg.sender] = amount; 
                return false;
            }
        }
        return true;
    }

    //时间戳转时间
    function timestampToTime(uint256 timestamp) internal pure returns(string memory){
        //获取年月日时分秒
        uint256 yeared = DateTime.getYear(timestamp);
        uint256 monthed = DateTime.getMonth(timestamp);
        uint256 dayed = DateTime.getDay(timestamp);
        uint256 houred = DateTime.getHour(timestamp);
        string memory h;
        if(houred<10){
            h = string(abi.encodePacked("0",intToStr(houred)));
        }else{
            h = intToStr(houred);
        }
        uint256 minuteed = DateTime.getMinute(timestamp);
        string memory m;
        if(minuteed<10){
            m = string(abi.encodePacked("0",intToStr(minuteed)));
        }else{
            m = intToStr(minuteed);
        }
        uint256 seconded = DateTime.getSecond(timestamp);
        string memory s;
        if(seconded<10){
            s = string(abi.encodePacked("0",intToStr(seconded)));
        }else{
            s = intToStr(seconded);
        }
        string memory Times = string(abi.encodePacked(intToStr(yeared),"-",intToStr(monthed),"-",intToStr(dayed)," ",h,":",m,":",s));
        return Times;
    }

    // 获取剩余时间
    function getRemainderTime(uint256 timestamp) internal pure returns(string memory){
        uint256 minuteed = DateTime.getMinute(timestamp);
        string memory m;
        if(minuteed<10){
            m = string(abi.encodePacked("0",intToStr(minuteed)));
        }else{
            m = intToStr(minuteed);
        }
        uint256 seconded = DateTime.getSecond(timestamp);
        string memory s;
        if(seconded<10){
            s = string(abi.encodePacked("0",intToStr(seconded)));
        }else{
            s = intToStr(seconded);
        }
        string memory Times = string(abi.encodePacked(m,":",s));
        return Times;
    }

    //uint256ToString
    function intToStr(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j > 0) {
            j /= 10;len++;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i > 0) {
            bstr[k] = byte(uint8( 48 + _i % 10));
            _i /= 10;
            k--;  
        }
        return string(bstr);
    }
}

library DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) internal pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) internal pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) internal pure returns (uint8) {
                uint256 dayee = (timestamp + 3600 * 8) % 86400;
                return uint8(dayee / 3600);
        }

        function getMinute(uint timestamp) internal pure returns (uint8) {
                uint256 dayee = (timestamp + 3600 * 8) % 86400;
                return uint8(dayee % 3600 / 60);
        }

        function getSecond(uint timestamp) internal pure returns (uint8) {
                uint256 dayee = (timestamp + 3600 * 8) % 86400;
                return uint8(dayee % 60);
        }

        function getWeekday(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) internal pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}