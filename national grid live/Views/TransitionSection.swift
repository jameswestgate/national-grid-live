import SwiftUI

struct TransitionSection: View {
    var body: some View {
        Card {
            VStack(spacing: 0) {
                CardHeader(title: "The energy transition")
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Self.paragraphs, id: \.self) { p in
                        Text(p)
                            .font(.appSerif(.body))
                            .foregroundStyle(Palette.contentText)
                    }

                    Text("Wind power records are set regularly")
                        .font(.appSerif(.headline, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 6)

                    milestonesTable
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
    }

    private static let paragraphs: [String] = [
        "Between 12th January 1882, when the world's first coal-fired power station opened at 57 Holborn Viaduct in London, and 30th September 2024, when Great Britain's last coal-fired power station closed, the country burnt 4.6 billion tonnes of coal, emitting 10.6 billion tonnes of carbon dioxide.",
        "In 2001 the European Union updated the Large Combustion Plant Directive, obliging power stations to limit their emissions or close by 2015. Most older coal-fired power stations in Great Britain closed in response. The government's introduction of a carbon price floor in 2013, and its subsequent increase in 2015, made coal uncompetitive with gas, which rapidly replaced coal in the country's energy mix.",
        "At the same time, renewable power generation was steadily rising. Great Britain's exposed position in the north-east Atlantic makes it one of the best locations in the world for wind power, and the shallow waters of the North Sea host several of the world's largest offshore wind farms.",
        "Between 5:30pm and 6:00pm on 5th December 2025, British wind farms averaged a record 23.94GW of generation."
    ]

    private struct Milestone: Hashable {
        let power: String
        let date: String
    }

    private static let milestones: [Milestone] = [
        .init(power: "23GW", date: "5th December 2025"),
        .init(power: "22GW", date: "5th December 2024"),
        .init(power: "21GW", date: "10th January 2023"),
        .init(power: "20GW", date: "2nd November 2022"),
        .init(power: "15GW", date: "18th December 2018"),
        .init(power: "10GW", date: "8th December 2016")
    ]

    private var milestonesTable: some View {
        VStack(spacing: 0) {
            row(power: "Power", date: "Date first achieved", isHeader: true)
            ForEach(Array(Self.milestones.enumerated()), id: \.element) { idx, m in
                row(power: m.power, date: m.date, stripe: idx.isMultiple(of: 2))
            }
        }
    }

    private func row(power: String, date: String, isHeader: Bool = false, stripe: Bool = false) -> some View {
        HStack {
            Text(power)
                .font(.appSerif(.callout, weight: isHeader ? .semibold : .regular))
                .frame(width: 80, alignment: .leading)
                .monospacedDigit()
            Text(date)
                .font(.appSerif(.callout, weight: isHeader ? .semibold : .regular))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(stripe && !isHeader ? Palette.tableStripe : Color.clear)
    }
}

#Preview {
    TransitionSection()
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
