////
///  SearchScreenSpec.swift
//

import Quick
import Nimble
import Ello
import Nimble_Snapshots

public class MockSearchScreenDelegate: NSObject, SearchScreenDelegate {
    var searchFieldWasCleared = false
    public func searchCanceled(){}
    public func searchFieldCleared(){searchFieldWasCleared = true}
    public func searchFieldChanged(text: String, isPostSearch: Bool){}
    public func searchShouldReset(){}
    public func toggleChanged(text: String, isPostSearch: Bool){}
    public func findFriendsTapped(){}
}

class SearchScreenSpec: QuickSpec {
    override func spec() {

        describe("SearchScreen") {
            var subject: SearchScreen!

            beforeEach {
                subject = SearchScreen(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 568)), isSearchView: true, navBarTitle: "Test", fieldPlaceholderText: "placeholder test")
            }

            context("searching for people") {
                it("should set the search text to 'atsign' if the search field is empty") {
                    subject.searchField.text = ""
                    subject.onPeopleTapped()
                    expect(subject.searchField.text) == "@"
                }

                it("should set the search text to 'atsign' if the search field is null") {
                    subject.searchField.text = nil
                    subject.onPeopleTapped()
                    expect(subject.searchField.text) == "@"
                }

                it("should clear the search text if it was 'atsign' and you search for posts") {
                    subject.onPeopleTapped()
                    subject.searchField.text = "@"
                    subject.onPostsTapped()
                    expect(subject.searchField.text) == ""
                }
            }

            context("hasBackButton") {
                it("has a back button by default") {
                    let prevItems = subject.navigationItem.leftBarButtonItems
                    expect(subject.hasBackButton) == true
                    expect(subject.navigationItem.leftBarButtonItem) == prevItems![0]

                    showView(subject)
                    expect(subject).to(haveValidSnapshot(named: "hasBackButton:true"))
                }

                it("can have a close button instead (left item changes)") {
                    let prevItems = subject.navigationItem.leftBarButtonItems
                    subject.hasBackButton = false
                    expect(subject.hasBackButton) == false
                    expect(subject.navigationItem.leftBarButtonItem) != prevItems![0]

                    showView(subject)
                    expect(subject).to(haveValidSnapshot(named: "hasBackButton:false"))
                }

                it("can have an explicit back button (left item changes)") {
                    var prevItems = subject.navigationItem.leftBarButtonItems
                    subject.hasBackButton = false
                    expect(subject.navigationItem.leftBarButtonItem) != prevItems![0]

                    prevItems = subject.navigationItem.leftBarButtonItems
                    subject.hasBackButton = true
                    expect(subject.hasBackButton) == true
                    expect(subject.navigationItem.leftBarButtonItem) != prevItems![0]

                    showView(subject)
                    expect(subject).to(haveValidSnapshot(named: "hasBackButton:true"))
                }
            }

            context("UITextFieldDelegate") {

                describe("textFieldShouldReturn(_:)") {

                    it("returns true") {
                        let shouldReturn = subject.textFieldShouldReturn(subject.searchField)

                        expect(shouldReturn) == true
                    }

                    it("hides keyboard") {
                        subject.textFieldShouldReturn(subject.searchField)

                        expect(subject.searchField.isFirstResponder()) == false
                    }
                }

                describe("textFieldShouldClear(_:)") {

                    it("returns true") {
                        let shouldReturn = subject.textFieldShouldClear(subject.searchField)

                        expect(shouldReturn) == true
                    }

                    it("calls search field cleared on it's delegate") {

                        let delegate = MockSearchScreenDelegate()
                        subject.delegate = delegate
                        subject.textFieldShouldClear(subject.searchField)

                        expect(delegate.searchFieldWasCleared) == true
                    }

                    context("is search view") {

                        beforeEach {
                            subject = SearchScreen(frame: CGRectZero, isSearchView: true, navBarTitle: "Test", fieldPlaceholderText: "placeholder test")
                        }

                        it("hides find friends text") {
                            subject.textFieldShouldClear(subject.searchField)

                            expect(subject.findFriendsContainer.hidden) == false
                        }
                    }

                    context("is NOT search view") {

                        beforeEach {
                            subject = SearchScreen(frame: CGRectZero, isSearchView: false, navBarTitle: "Test", fieldPlaceholderText: "placeholder test")
                        }

                        it("shows find friends text") {
                            subject.textFieldShouldClear(subject.searchField)

                            expect(subject.findFriendsContainer.hidden) == true
                        }
                    }
                }
            }
        }
    }
}

