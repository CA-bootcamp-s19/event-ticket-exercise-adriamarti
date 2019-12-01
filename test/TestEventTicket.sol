pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTickets.sol";
import "../contracts/EventTicketsV2.sol";

contract TestEventTicket {

  string DESCRIPTION = "description";
  string URL = "URL";
  uint TICKET_NUMBER = 100;

  function testSalesAreOpenWhenContractIsCreated() public {
    EventTickets eventTickets = new EventTickets(DESCRIPTION, URL, TICKET_NUMBER);

    (, , , , bool isOpen) = eventTickets.readEvent();

    Assert.equal(isOpen, true, "the event should be open");
  }

  function testReadEventFunction() public {
    EventTickets eventTickets = new EventTickets(DESCRIPTION, URL, TICKET_NUMBER);

    (string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) = eventTickets.readEvent();
    

    Assert.equal(description, DESCRIPTION, "the event descriptions should match");
    Assert.equal(website, URL, "the event urls should match");
    Assert.equal(totalTickets, TICKET_NUMBER, "the number of tickets for sale should be set");
    Assert.equal(sales, 0, "the ticket sales should be 0");
    Assert.equal(isOpen, true, "the event should be open");
  }

}