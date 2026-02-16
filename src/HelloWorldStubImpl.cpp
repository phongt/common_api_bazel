// HelloWorldStubImpl.cpp
#include "HelloWorldStubImpl.hpp"
#include <algorithm>
#include <cctype>

HelloWorldStubImpl::HelloWorldStubImpl(): cnt(0) {
}

HelloWorldStubImpl::~HelloWorldStubImpl() {
}

void HelloWorldStubImpl::sayHello(const std::shared_ptr<CommonAPI::ClientId> _client,
        std::string _name, sayHelloReply_t _reply) {

    std::stringstream messageStream;

    messageStream << "Hello " << _name << "!";
    std::cout << "sayHello('" << _name << "'): '" << messageStream.str() << "'\n";

    _reply(messageStream.str());

    std::string greeting = messageStream.str();

    std::transform(greeting.begin(), greeting.end(), greeting.begin(), ::toupper);

    fireGreetingEvent(greeting);
};

void HelloWorldStubImpl::incCounter() {
    cnt++;
    setXAttribute((int32_t)cnt);
    std::cout <<  "New counter value = " << cnt << "!" << std::endl;
}