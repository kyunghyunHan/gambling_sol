// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CommitRevealLottery {
    //커밋이 종료 블록넘버
    uint256 public commitCloses;
    //reveal종료 블록넘버
    uint256 public revealCloses;
    //commit및 reveal진행기간 4block
    uint256 public constant DURATION= 4;

    uint256 public lotteryId;
    address[] public players;
    //이번회차 승리자
    address public winner;
    //매회차시 reveal시 얻는 secret값에 의해 업데이트 되는 랜덤값
    bytes32 seed;
   //참여자가 제실한 commit값 생성자에서 첫회차의commit,reveal기간을 제함
    mapping (address =>bytes32)public commitments; 
    mapping (uint256=>address)public lotteryHistory;

    constructor(){
        commitCloses= block.number + DURATION;
        revealCloses= commitCloses+DURATION; 
    }
    /* 
    참여자는 외부에서 secret값을  생성한후 해시하여 commit값 생성후 0.01이상의 ETH와함계 commit값 등록
    commit이 종료되는 블록 넘버 이전까지 참여가능
    각 참여자마다 commit값 등록
     */
    function enter(bytes32 commitment) public payable {
     require(msg.value>=0.01 ether,"msg.value should be greater then or equal to 0.01 ether");    
     require(block.number < commitCloses,"commit duration is over");


     commitments[msg.sender]= commitment;
     
     }
/* 이 컨트렉트에서의 commit값 생성 로직
    commit값 생성로직
    - 함수를 콜한 주소와 입력한 secret값을 해시한값

 */
     function createCommitment(uint256 secret)public view returns(bytes32){
        return keccak256(abi.encodePacked(msg.sender,secret));

     }
  /* 
  reveal

  - 커밋지 참여했던 자가 그 당시 사용한 secret값 공개하며 이를 이용해 랜던한 값 생성
  - commit기간종료후부터 reveal기간 종료 전까지만 가능
  - 입력한 secret값에 대해 해시한 값이 commit시 등록한 해시값과 일치하는지 확인
  - 입력하면 이를 seed값에 이어서 해시 
   */
     function reveal(uint256 secret)public {
        require(block.number >=commitCloses,"commit duration is not closed yer");
        require(block.number < revealCloses,"reveal dyration is already closed");

        bytes32 commit = createCommitment(secret);
        require(commit==commitments[msg.sender],"commit not matches");

        seed= keccak256(abi.encodePacked(seed,secret));
        players.push(msg.sender);
     }
     


     /*pickwinner 
     - reveal단계에서 결정된 랜덤값인 seed를 통해 참여한 players중 winner선정
     - 충분한 참여기간 지난 후에 호출 가능하므로 onlyOwner일 필요엇음

    */
    
    function pickWinner()public{
        require(block.number>=revealCloses,"Not yet to pick winner");
        require(winner ==address(0),"winner is already set");

        winner= players[uint256(seed) % players.length];
        
        lotteryHistory[lotteryId]= winner;
        lotteryId++;
    }
    /*

    withdreaPize()
    - 함수 호출자가 winner일 경우 컨트랙트에 쌓인 모든 ETH 획득
    - re-entrancy attack방지 위해 call호출전에 상태값 변경
    - 다음 회차를 위해 관련데이터들 초기화 및 commit,reveal기간 재설정

    */
    function withdrawPrize()public{
     require(msg.sender ==winner,"you`re not the winner");

     //initialize for next phase

     delete winner;
     for (uint256 i= 0;i<players.length;i++){
        delete commitments[players[i]];
     }
     delete players;
     delete seed;

     commitCloses= block.number + DURATION;
     revealCloses= commitCloses+DURATION;

     (bool success,)= payable(msg.sender).call{value:address(this).balance}("");
     require(success,"Falid to send Ether to Winner");
    }
}