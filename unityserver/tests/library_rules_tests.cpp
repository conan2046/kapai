#include "../src/library_rules.h"
#include <cassert>
#include <iostream>
#include <climits>

int main() {
    const std::vector<int> members={1,2,3,4};
    // Obtained/owned history cannot unlock multi-book rewards before activation.
    assert(!library::Satisfied("count",2,{},members,{}));
    assert(!library::Satisfied("count",2,{},members,{1,99}));
    assert(library::Satisfied("count",2,{},members,{1,2,99}));
    assert(!library::Satisfied("complete",0,{},members,{1,2,3}));
    assert(library::Satisfied("complete",0,{},members,{1,2,3,4,99}));
    assert(!library::Satisfied("combination",0,{2,4},members,{1,2,3}));
    assert(library::Satisfied("combination",0,{2,4},members,{2,4}));
    assert(library::Satisfied("complete",0,{},std::vector<int>{9},{9}));
    assert(!library::Satisfied("complete",0,{},std::vector<int>{},{}));
    assert(library::Sale(100,3)==300);
    assert(library::Sale(0,3)==0);
    assert(library::Sale(INT_MAX,65535)==static_cast<int64_t>(INT_MAX)*65535);
    bool rejected=false;try{library::Sale(-1,1);}catch(const std::exception&){rejected=true;}assert(rejected);
    std::cout<<"Library rules: activation scope, 1..4-book thresholds and 64-bit sale passed.\n";
}
