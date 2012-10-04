#!/usr/bin/env python

# Copyright (c) 2012 the authors listed at the following URL, and/or
# the authors of referenced articles or incorporated external code:
# http://en.literateprograms.org/Stack_(Python)?action=history&offset=20101224060000
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# Retrieved from: http://en.literateprograms.org/Stack_(Python)?oldid=17006


class EmptyStackException(Exception):
    pass

class Element:
    def __init__(self, value, next):
        self.value = value
        self.next = next

class Stack:
    def __init__(self):
        self.head = None

    
    def push(self, element):
        self.head = Element(element, self.head)

    
    def pop(self):
        if self.empty(): raise EmptyStackException
        result = self.head.value
        self.head = self.head.next
        return result
    
    def empty(self):
        return self.head == None

if __name__ == "__main__":
    
    stack = Stack()
    elements = ["first", "second", "third", "fourth"]
    for e in elements:
        stack.push(e)

    result = []
    while not stack.empty():
        result.append(stack.pop())

    assert result == ["fourth", "third", "second", "first"]
