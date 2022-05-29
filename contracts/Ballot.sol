pragma solidity >=0.7.0 <0.9.0;

/// @title Voting with delegation

contract Ballot {
    // struct representing a single voter
    struct Voter {
        uint256 weight; //Its accumulated by delegation
        bool voted;
        address delegate; //person delegated to
        uint256 vote; //index of the voted proposal
    }

    //This is a type for a single proposal
    struct Proposal {
        bytes32 name; //short name(upto 32 bytes)
        uint256 voteCount; //number of accumulated votes
    }

    address public chairperson;

    //Declares a state variable that stores 'Voter' struct for each address
    mapping(address => Voter) public voters;

    //A dynamically sized array of 'Proposal' structs
    Proposal[] public proposals;

    ///Create a new ballot to choose one of 'proposalNames'
    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        //For each of the provided proposal names
        //create a new proposal object and add it
        //to end of array
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    //Give voter the right to vote on this ballot
    //May only be called by the 'chairperson'
    function giveRightToVote(address voter) external {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote"
        );
        require(!voters[voter].voted, "The voter already voted");
        require(voters[voter].weight == 0,"Right to vote already given");
        voters[voter].weight = 1;
    }

    /// Delegate your vote to the voter `to`
    function delegate(address to) external {
        //assigns reference
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "You have no right to vote");
        require(!sender.voted, "You already voted");

        require(to != msg.sender, "Self-delegation is diallowed.");

        //Forward the delegation as long as 'to' also delegated
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            //Found a loop in delegation so revert
            require(to != msg.sender, "Found loop in delegation");
        }

        //Since sender is a reference, this modifies `voters[msg.sender].voted`
        Voter storage delegate_ = voters[to];

        //Voters cannot delegagte to accounts that cannot vote
        require(delegate_.weight >= 1);
        sender.voted = true;
        sender.delegate = to;
        if (delegate_.voted) {
            // If delegate already voted add to the number of votes
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            // If delegate did not vote yet, add to their weight
            delegate_.weight += sender.weight;
        }
    }

    /// Give your vote (including votes delegated to you)
    /// to proposal `proposals[proposal].name`
    function vote(uint256 proposal) external {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "already voted");
        sender.voted = true;
        sender.vote = proposal;

        // If `proposal` is out of range of array, this will throw automatcally
        // and revert all changes
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev Computes the winning proposal taking all previous votes into account.
    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    //Calls winningProposal() function to get the index of winner contained in
    // proposals array and returns name of winner
    function winnerName() external view returns (bytes32 winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }
}
