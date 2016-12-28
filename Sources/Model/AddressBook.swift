////
///  AddressBook.swift
//

import Contacts
import Result

public protocol AddressBookProtocol {
    var localPeople: [LocalPerson] { get }
}

public struct AddressBook: AddressBookProtocol {
    public let localPeople: [LocalPerson]

    public init(store: CNContactStore) {
        localPeople = getAllPeopleWithEmailAddresses(store)
    }
}

private func getAllPeopleWithEmailAddresses(_ store: CNContactStore) -> [LocalPerson] {
    var persons: [LocalPerson] = []

    let fetchRequest = CNContactFetchRequest(keysToFetch: [
        CNContactEmailAddressesKey as CNKeyDescriptor,
        CNContactIdentifierKey as CNKeyDescriptor,
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName)
        ])
    do {
        try store.enumerateContacts(with: fetchRequest) { contact, _ in
            let emails = contact.emailAddresses.flatMap { $0.value as String }
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? emails.first ?? "NO NAME"
            let id = contact.identifier

            persons.append(LocalPerson(name: name, emails: emails, id: id))
        }
    }
    catch {
        persons = []
    }

    return persons.filter { $0.emails.count > 0 }
}
