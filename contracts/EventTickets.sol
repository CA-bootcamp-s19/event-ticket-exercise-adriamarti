pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
    address payable public owner;
    uint TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    Event private myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */
    event LogBuyTickets(address buyer, uint amount);
    event LogGetRefund(address refunded, uint amount);
    event LogEndSale(address owner, uint amount);
    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier verifyCaller() { require (msg.sender == owner); _;}
    modifier isEventOpen() { require (myEvent.isOpen == true); _;}
    modifier enoughAvailableTickets(uint _tickets) { require(myEvent.totalTickets - myEvent.sales >= _tickets); _;}
    modifier paidEnough(uint _tickets) { require(msg.value >= TICKET_PRICE * _tickets); _;}
    modifier hasTickets(address _addres) { require(myEvent.buyers[_addres] > 0); _;}
    modifier checkValue(uint _tickets) {
        _;
        uint amountToRefund = msg.value - TICKET_PRICE * _tickets;
        msg.sender.transfer(amountToRefund);
    }

    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor(string memory _description, string memory _url, uint _tickets) public {
        owner = msg.sender;
        myEvent.description = _description;
        myEvent.website = _url;
        myEvent.totalTickets = _tickets;
        myEvent.isOpen = true;
    }

    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent()
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        description = myEvent.description;
        website = myEvent.website;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isOpen = myEvent.isOpen;
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address _buyerAddress)
        public
        view
        hasTickets(_buyerAddress)
        returns(uint tickets)
    {
        require(myEvent.buyers[_buyerAddress] > 0, "This buyer didn't buy any ticket");
        tickets = myEvent.buyers[_buyerAddress];
    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
    function buyTickets(uint _tickets)
        public
        payable
        isEventOpen
        enoughAvailableTickets(_tickets)
        paidEnough(_tickets)
        checkValue(_tickets)
    {
        uint _availableTickets = myEvent.totalTickets - myEvent.sales;
        myEvent.buyers[msg.sender] += _tickets;
        myEvent.sales += _tickets;

        if (_availableTickets == _tickets) {
            myEvent.isOpen = false; 
        }

        emit LogBuyTickets(msg.sender, _tickets);
    }
    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */
    function getRefund()
        public
        hasTickets(msg.sender)
    {
        uint ticketsToRefund = myEvent.buyers[msg.sender];
        uint amountToRefund = ticketsToRefund * TICKET_PRICE;
        myEvent.totalTickets += ticketsToRefund;
        myEvent.sales -= ticketsToRefund;

        msg.sender.transfer(amountToRefund);

        myEvent.buyers[msg.sender] = 0;

        emit LogGetRefund(msg.sender, amountToRefund);
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale()
        public
        verifyCaller
    {
        uint contractBalance = address(this).balance;
        myEvent.isOpen = false;
        owner.transfer(contractBalance);

        emit LogEndSale(msg.sender, contractBalance);
    }
}
