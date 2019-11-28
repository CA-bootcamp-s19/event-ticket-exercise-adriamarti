pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
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
        uint id;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier verifyCaller() { require (msg.sender == owner); _;}
    modifier isEventOpen(uint _ticketId) { require (events[_ticketId].isOpen == true); _;}
    modifier enoughAvailableTickets(uint _ticketId, uint _tickets) {
        require(events[_ticketId].totalTickets - events[_ticketId].sales >= _tickets); _;
    }
    modifier paidEnough(uint _tickets) {
        require(msg.value >= PRICE_TICKET * _tickets); _;
    }
    modifier checkValue(uint _tickets) {
        _;
        uint amountToRefund = msg.value - PRICE_TICKET * _tickets;
        msg.sender.transfer(amountToRefund);
    }
    modifier hasTickets(uint _ticketId) { require(events[_ticketId].buyers[msg.sender] > 0); _;}

    /*
        Define a constructor.
        Set the owner to the creator of the contract.
    */
    constructor() public {
        owner = msg.sender;
    }

    function() external payable {
        revert();
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _url, uint _tickets)
        public
        verifyCaller
        returns(uint)
    {
        events[idGenerator].description = _description;
        events[idGenerator].website = _url;
        events[idGenerator].totalTickets = _tickets;
        events[idGenerator].isOpen = true;
        events[idGenerator].id = idGenerator;
        idGenerator += 1;
        emit LogEventAdded(_description, _url, _tickets, idGenerator);

        return idGenerator - 1;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventId)
        public
        view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        description = events[_eventId].description;
        website = events[_eventId].website;
        totalTickets = events[_eventId].totalTickets;
        sales = events[_eventId].sales;
        isOpen = events[_eventId].isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _ticketId, uint _tickets)
        public
        payable
        isEventOpen(_ticketId)
        enoughAvailableTickets(_ticketId, _tickets)
        paidEnough(_tickets)
        checkValue(_tickets)
    {
        events[_ticketId].buyers[msg.sender] += _tickets;
        events[_ticketId].sales += _tickets;
        emit LogBuyTickets(msg.sender, _ticketId, _tickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _ticketId)
        public
        hasTickets(_ticketId)
    {
        uint ticketsToRefund = events[_ticketId].buyers[msg.sender];
        events[_ticketId].sales -= ticketsToRefund;
        msg.sender.transfer(ticketsToRefund * PRICE_TICKET);
        emit LogGetRefund(msg.sender, _ticketId, ticketsToRefund);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _ticketId)
        public
        view
        returns(uint totalTickets)
    {
        totalTickets = events[_ticketId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _ticketId)
        public
        verifyCaller
    {
        events[_ticketId].isOpen = false;
        uint eventBalanceSales = events[_ticketId].sales * PRICE_TICKET;
        owner.transfer(eventBalanceSales);

        emit LogEndSale(msg.sender, eventBalanceSales, _ticketId);
    }
}
