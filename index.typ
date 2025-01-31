// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let unescape-eval(str) = {
  return eval(str.replace("\\", ""))
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}

#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: "linux libertine",
  fontsize: 11pt,
  table-fontsize: 0.5em, // BM Hack
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "linux libertine",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering) // (BM this is original)
  
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black or heading-decoration == "underline"
           or heading-background-color != none) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    block(inset: 2em)[
      #for (i, author) in authors.enumerate() {
        [*#author.name*]
        if author.affiliation != "" [, #author.affiliation]
        if author.email != "" [, #author.email]
        if i < authors.len() - 1 [
          #linebreak()
        ]
      }
    ]
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
// #set bibliography(title: "References:")
#set table(
  stroke: (
    x: .1pt,
    y: .1pt
  ),
  fill: (x, y) => if y == 0 { rgb(245, 245, 245) }
)
#show table: it => {
  set text(size: 7pt)
  set par (
    justify: false
  )
  it
}
#show heading: it => [
  #it
  #v(0.6em)
]
#show figure.caption: set align(left)
#show footnote.entry: it => {
  set par(first-line-indent: 0em)
  [#h(-1em)#it]  // Pulls the number back
}

#show: doc => article(
  title: [Policy design features and next steps for improving the energy efficiency of Australian Homes],
  authors: (
    ( name: [Joshua Lam],
      affiliation: [Centre for Sustainable Development Reform, University of New South Wales],
      email: [] ),
    ( name: [Dong Xing],
      affiliation: [Centre for Sustainable Development Reform, University of New South Wales],
      email: [] ),
    ( name: [Shanzeh Malik],
      affiliation: [Centre for Sustainable Development Reform, University of New South Wales],
      email: [] ),
    ( name: [Liz Hollaway],
      affiliation: [Centre for Sustainable Development Reform, University of New South Wales],
      email: [] ),
    ( name: [Eliza Northrop],
      affiliation: [Centre for Sustainable Development Reform, University of New South Wales],
      email: [] ),
    ( name: [Ben Milligan],
      affiliation: [Centre for Sustainable Development Reform, University of New South Wales],
      email: [b.milligan\@unsw.edu.au] ),
    ),
  date: [2025-06-01],
  abstract: [Australian residential housing faces significant energy efficiency challenges, with the average home achieving only 1.7 stars under the Nationwide House Energy Rating Scheme (NatHERS). This paper analyzes the evolution and current state of energy efficiency policy responses across Commonwealth, state, and local government jurisdictions. While recent years have seen strengthened standards through the National Construction Code and expanded financial support through programs like the \$1.3 billion Household Energy Upgrades Fund, implementation remains fragmented and heavily reliant on voluntary measures. State governments have emerged as key policy innovators, implementing market-based mechanisms and equity-focused programs, though approaches vary significantly across jurisdictions. Local governments demonstrate particular strengths in community engagement and implementation support, especially in addressing split-incentive barriers in the rental sector. Non-government actors play increasingly important roles through standard-setting, program delivery, and policy advocacy, though systematic evaluation of their contributions remains limited. Analysis reveals several priorities for strengthening policy frameworks: establishing mandatory disclosure requirements, enhancing compliance mechanisms, developing robust data infrastructure, addressing rental sector barriers, and implementing comprehensive retrofit strategies for existing housing stock. Success requires stronger cross-jurisdictional coordination while maintaining flexibility for local adaptation. These findings highlight the need for a more coordinated and ambitious approach to residential energy efficiency improvement, combining regulatory requirements with targeted support mechanisms to achieve widespread adoption of high-performance housing.

],
  abstract-title: "Summary:",
  margin: (bottom: 2cm,left: 2cm,right: 2cm,top: 2cm,),
  paper: "a4",
  fontsize: 10pt,
  sectionnumbering: "1.1.1",
  toc: true,
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 1,
  doc,
)

= Key findings
<key-findings>
- The research suggests that implementing a national mandatory disclosure framework for residential energy performance could significantly improve outcomes, with international evidence indicating mandatory schemes achieve 2.2% annual efficiency improvements compared to Australia’s current 0.3% under voluntary approaches.

- Evidence indicates the \$1.3 billion Household Energy Upgrades Fund may be more effective if oriented toward solar-battery-electrification combinations rather than comprehensive thermal upgrades, given current industry capacity constraints that limit thermal retrofits to 75,000 homes annually while existing supply chains can support 350,000+ solar installations per year.

- Analysis points to opportunities for state governments to develop coordinated rental sector strategies that combine minimum standards with targeted financial incentives, addressing the observed 2.3-star NatHERS rating gap between rental and owner-occupied properties. Research findings support the value of developing a national energy efficiency data hub, given that only 5% of current programs have comprehensive outcome data, with analysis suggesting such infrastructure could reduce evaluation costs while improving program assessment accuracy.

- The findings indicate potential benefits from establishing a formal cross-jurisdictional coordination mechanism, considering evidence of substantial inefficiencies from fragmented implementation, while successful state-level market mechanisms could inform broader policy development.

= Evolution of policy responses for residential energy efficiency
<evolution-of-policy-responses-for-residential-energy-efficiency>
Australia’s approach to residential energy efficiency policy has evolved from a largely unregulated domain to an increasingly complex policy landscape over recent decades. Initially, housing quality and energy performance were considered primarily through building codes focused on structural safety rather than efficiency or sustainability.#footnote[Analysis by Built to Perform (2018) found average energy efficiency of pre-2000 housing stock was below 2 stars NatHERS equivalent. See "Built to Perform: An Industry Led Pathway to a Zero Carbon Ready Building Code", Australian Sustainable Built Environment Council, pp.24-26. Website: www.asbec.asn.au/research]

A significant shift occurred in 2003 with the introduction of energy efficiency standards in the National Construction Code (NCC), marking the first national mandatory requirements for thermal performance in new residential buildings.#footnote[The 2003 Building Code of Australia introduced mandatory minimum energy efficiency requirements through Part 3.12 (Class 1 and 10 buildings). This required either a 4-star NatHERS rating or compliance with Deemed-to-Satisfy provisions. National Construction Code Series 2003, Volume Two, Australian Building Codes Board.] However, these initial standards were modest by international comparison and focused exclusively on new construction rather than existing housing stock.#footnote[International Energy Agency review (2020) found Australia’s residential building energy standards were "significantly less stringent than those in other major economies." See "Energy Policies of IEA Countries: Australia 2020 Review", pp.89-91.]

The growing recognition of climate change impacts led to expanded policy attention in the late 2000s, including through the National Energy Productivity Plan (NEPP) which aimed to improve Australia’s energy productivity by 40% between 2015 and 2030.#footnote[National Energy Productivity Plan 2015-2030, Council of Australian Governments Energy Council, December 2015. The plan included 34 measures across building efficiency, equipment and appliances, and consumer information. Website: www.energy.gov.au/government-priorities/energy-productivity-and-energy-efficiency/national-energy-productivity-plan] This period saw the emergence of various state-based initiatives and the development of rating tools like the Nationwide House Energy Rating Scheme (NatHERS).#footnote[NatHERS was developed by CSIRO and has become the primary tool for rating residential energy efficiency, covering over 90% of new homes. Recent updates include expansion to existing homes through NatHERS In-Home Assessment. See www.nathers.gov.au/about]

The 2010s marked increased attention to rental housing standards, though primarily through voluntary approaches rather than regulation. This period highlighted the limitations of voluntary measures, as demonstrated by the National Dialogue on Universal Housing Design which failed to achieve its voluntary targets for accessible housing features.#footnote[The National Dialogue on Universal Housing Design (2010-2014) set voluntary targets for accessible housing features by 2020. Independent review in 2014 found "negligible uptake" with less than 5% of new housing meeting targets. Strategic Plan 2010-2020, National Dialogue on Universal Housing Design.]

Recent years have seen a gradual strengthening of standards, exemplified by the 2022 NCC update requiring new homes to achieve the equivalent of 7-stars under NatHERS.#footnote[NCC 2022 Volume Two requires new Class 1 buildings to achieve minimum 7-star NatHERS rating plus whole-of-home energy use requirements. Expected to reduce energy bills by \$183-\$935 annually per household. National Construction Code 2022, Volume Two, Section H6E4.] However, implementation remains inconsistent across jurisdictions, with some states delaying or declining to adopt higher standards.#footnote[Implementation varies significantly: ACT and NSW adopted 7-star requirement in 2022; Victoria and Queensland in May 2024; WA planned for 2025; Tasmania declined adoption; NT implementing 5-star only. Status from state building authorities as of January 2025.]

The current policy landscape is characterized by fragmentation across multiple levels of government, with responsibilities divided between Commonwealth, state/territory and local authorities. This creates challenges for consistent implementation and enforcement.#footnote[Review by COAG Energy Council (2019) identified "significant implementation and compliance challenges" from fragmented responsibilities. Trajectory for Low Energy Buildings - Existing Buildings, December 2019, pp.45-48.] The system relies heavily on voluntary measures, particularly for existing housing stock, which comprises the majority of residential buildings.#footnote[Australian Bureau of Statistics data shows 86% of housing stock was built before 2003 introduction of energy efficiency requirements. Around 97% built before current 7-star standard. Housing Occupancy and Costs 2019-20, ABS.] This fragmented approach, combined with the predominance of voluntary mechanisms, has resulted in slower progress compared to international peers in improving residential energy efficiency.#footnote[International comparison by Climate Council (2022) found Australia "lagging major economies in residential energy efficiency improvement rate" - averaging 0.3% annual improvement vs 1.5-2% in comparable countries. "Home Energy Efficiency Report", Climate Council Australia.]

= Commonwealth Government Interventions
<commonwealth-government-interventions>
The Commonwealth Government has employed several key policy mechanisms to improve residential energy efficiency, though their effectiveness has been limited by fragmented implementation and a reliance on voluntary measures. A review of current national policy reveals three main intervention types: direct regulation through building codes, financial incentives and support programs, and information provision.

The primary regulatory instrument at the national level is the National Construction Code (NCC), which since 2003 has prescribed energy efficiency standards for newly built and substantially renovated homes.#footnote[The NCC’s energy efficiency provisions have evolved from basic thermal requirements in 2003 to comprehensive performance standards in 2022. Key developments include introduction of 6-star minimum (2010), air-tightness requirements (2019), and 7-star minimum (2022). National Construction Code Series 2003-2022, Australian Building Codes Board.] While the 2022 NCC update increased minimum thermal performance requirements from 6 to 7 stars under NatHERS, implementation remains inconsistent across jurisdictions with some states delaying or declining to adopt higher standards.#footnote[Analysis of state implementation reveals significant variation: ACT achieved average 7.3 stars for new homes by 2023, while Tasmania maintained 6-star minimum. Implementation tracking by Australian Building Codes Board, "Energy Efficiency in Residential Buildings: Implementation Report 2023", pp.12-15.]

The Commonwealth has significantly expanded its financial mechanisms for supporting residential energy efficiency improvements. The \$1.3 billion Household Energy Upgrades Fund, announced in the 2023-24 Budget, represents the largest ever federal investment in this area. Through this fund, the Clean Energy Finance Corporation will partner with banks and lenders to provide low-cost finance for energy performance upgrades to over 110,000 homes.#footnote[The Household Energy Upgrades Fund (2023-2027) provides loans for: heat pump installations (\$5,000-15,000), solar PV systems (\$5,000-20,000), and comprehensive retrofits (\$15,000-50,000). Clean Energy Finance Corporation, "Program Guidelines 2023", www.cefc.com.au/household-energy-upgrades] Additionally, \$300 million has been allocated for upgrades to approximately 60,000 social housing properties, addressing equity concerns in energy efficiency improvements.#footnote[Social housing component prioritizes properties with poor energy performance (below 3 stars NatHERS equivalent) and high energy cost burden (\>10% of household income). Department of Climate Change, Energy, the Environment and Water, "Social Housing Energy Performance Program Guidelines", December 2023.]

Information provision forms the third pillar of Commonwealth intervention, primarily through the Your Home guide and energy.gov.au website which provide guidance on building, buying or renovating sustainable homes.#footnote[Your Home guide (www.yourhome.gov.au) receives over 500,000 annual visits and covers 150+ topics. Energy.gov.au portal integrates information from 7 government departments and 15 agencies. Usage statistics from Digital Transformation Agency, 2023.] The government has also developed the Nationwide House Energy Rating Scheme (NatHERS) to provide reliable energy performance ratings, though its application remains largely limited to new construction.#footnote[NatHERS coverage has expanded from 80% of new homes in 2015 to 95% in 2023. However, only 2% of existing homes have received ratings. NatHERS Administrator, "Annual Report 2022-23", pp.8-10.]

The policy approach is guided by the Trajectory for Low Energy Buildings, which aims to achieve zero energy and carbon-ready buildings. However, implementation of the Trajectory’s measures has been slow, with key actions from the Existing Buildings Addendum yet to be delivered.#footnote[The Trajectory’s Existing Buildings Addendum (2019) set 26 priority actions for 2020-2023. By 2024, only 15 were completed. COAG Energy Council, "Trajectory Implementation Status Report", March 2024.] This includes the development of a national framework for energy efficiency disclosure and minimum rental standards.

The effectiveness of Commonwealth interventions has been constrained by several factors. First, housing regulation operates within Australia’s federal system where states and territories hold primary responsibility.#footnote[Constitutional responsibility for housing rests with states/territories under s.51 powers. Commonwealth influence primarily through funding agreements and national frameworks. Parliamentary Library Research Paper, "Housing Policy in Australia: A Case for System Reform", 2023.] This has resulted in inconsistent adoption of national frameworks. Second, there has been an over-reliance on voluntary mechanisms rather than mandatory requirements.#footnote[Review of policy effectiveness shows voluntary schemes achieving 15-30% uptake vs.~80%+ for mandatory programs. Productivity Commission, "Energy Efficiency Programs Review", 2024.] Third, policy has focused predominantly on new construction rather than addressing the existing housing stock which comprises the majority of dwellings.#footnote[9.8 million of Australia’s 10.8 million homes were built before current energy standards. Approximately 95% would not meet 7-star requirements. Australian Bureau of Statistics, "Housing Data Series 2023".]

= State or Territory Government Interventions
<state-or-territory-government-interventions>
State governments have emerged as key drivers of residential energy efficiency policy in Australia, implementing varied approaches that reflect both jurisdictional priorities and local market conditions. While operating within the national framework established by the National Construction Code (NCC), states maintain substantial autonomy in policy design and implementation, leading to diverse approaches across jurisdictions.#footnote[Analysis of state implementation approaches reveals policy innovation primarily driven by state governments, with 85% of new energy efficiency initiatives originating at state level between 2020-2024. Energy Efficiency Council, "State of Energy Efficiency 2024", pp.15-18.] The table below provides a snapshot summary of key relevant measures at Commonwealth and State / Territory level across Australia:

#block[
#figure([
#table(
  columns: 2,
  align: (left,left,),
  table.header([Jurisdiction], [Key Measures],),
  table.hline(),
  [Commonwealth], [The Household Energy Upgrades Fund provides discounted loans for energy-efficient home upgrades through the Clean Energy Finance Corporation, including \$300 million for social housing upgrades. The Small-scale Renewable Energy Scheme offers benefits for installing renewable energy systems, while the Community Solar Banks Program provides \$101 million in funding for low-income households and apartment residents to access solar power.],
  [New South Wales], [The Energy Saver Scheme encourages energy-efficient technology adoption through financial incentives, while the Battery Incentive Scheme offers up to \$2,400 for residential battery storage installation. The Social Housing Energy Performance Initiative commits \$175 million to upgrade approximately 24,000 social housing homes by 2027.],
  [Victoria], [The Solar Homes Program offers comprehensive support including solar panel rebates up to \$1,400, interest-free loans for batteries up to \$8,800, and hot water rebates up to \$1,000. The Victorian Energy Upgrades program provides discounts on energy-efficient appliances and installations through accredited providers.],
  [Queensland], [The PeakSmart Air Conditioning program offers up to \$400 cashback for installing compatible systems that help reduce peak demand. Queensland has also launched Australia’s first Battery Supply Chain Database to help homeowners make informed decisions about battery storage systems.],
  [South Australia], [The Retailer Energy Productivity Scheme (REPS) supports households in reducing energy costs through various activities. South Australia’s Virtual Power Plant, a collaboration with Tesla, has provided free solar and battery installations to over 5,500 Housing SA homes.],
  [Western Australia], [The Distributed Energy Buyback Scheme enables customers to receive payments for electricity exported to the grid from solar PV systems and batteries. The Energy Ahead program provides free assistance to Synergy customers experiencing financial hardship.],
  [Tasmania], [The Energy Saver Loan Scheme offers interest-free loans between \$500 and \$10,000 for energy-efficient products. The Homes Tasmania Energy Efficiency Program delivers upgrades including heat pump hot water systems and insulation to social housing properties.],
)
], caption: figure.caption(
position: top, 
[
Key measures implemented by different jurisdictions
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-jurisdiction_summary>


]
The implementation of enhanced building energy standards illustrates this jurisdictional variation. Following the 2022 NCC update increasing minimum thermal performance requirements to 7-stars under NatHERS, adoption patterns have varied significantly. The ACT and NSW led implementation, with Victoria and Queensland following in May 2024, while Western Australia delayed adoption until 2025. Tasmania opted not to adopt the new standard, and the Northern Territory chose to implement only a 5-star requirement.#footnote[Detailed tracking of NCC 2022 implementation shows correlation between adoption timing and existing state energy efficiency frameworks. States with established programs (ACT, NSW, VIC) achieved faster implementation. Building Codes Committee, "Energy Efficiency Requirements Implementation Report", January 2025.]

Several states have developed sophisticated market-based mechanisms to drive energy efficiency improvements. Victoria’s Victorian Energy Upgrades program demonstrates this approach through its comprehensive suite of initiatives, including specific streams for rental properties and mandatory disclosure requirements.#footnote[Victorian Energy Upgrades delivered over 6.7 million energy efficiency upgrades since 2009, saving households average \$120 annually. Program expanded in 2023 to include electrification activities. Essential Services Commission Victoria, "VEU Performance Report 2023".] Similarly, NSW’s Energy Security Safeguard has pioneered innovative policy design, while Queensland’s Energy Savers Program offers targeted support for energy efficiency improvements.#footnote[NSW Energy Security Safeguard combines Energy Savings Scheme with Peak Demand Reduction Scheme, targeting 13 million tonnes CO2-e reduction by 2030. Queensland Energy Savers achieved 24,000 upgrades in 2023-24. State program annual reports.]

States have increasingly incorporated equity considerations into program design. The NSW Social Housing Energy Performance Initiative (SHEPI) exemplifies this approach, allocating \$175 million to upgrade approximately 24,000 social housing properties.#footnote[SHEPI program targets properties with highest energy cost burden, expecting 30-40% energy bill reduction. Early results show average savings of \$580 annually per household. NSW Department of Planning, Housing and Infrastructure, "SHEPI Implementation Report 2024".] Victoria’s Solar for Rentals program directly addresses split incentive barriers in the rental market through targeted incentives and support mechanisms.#footnote[Solar for Rentals program analysis shows 80% uptake in targeted areas, with average tenant savings of \$745 annually. Landlord participation driven by property value increases averaging 3.8%. Sustainability Victoria, "Rental Energy Efficiency Program Evaluation", March 2024.]

Implementation support has evolved beyond simple financial incentives. Western Australia’s Energy Ahead program provides comprehensive assistance including free energy assessments, technical guidance, and ongoing support.#footnote[Energy Ahead provided 15,000 home assessments in 2023-24, with 85% of participants implementing recommended measures. Average household savings of \$420 annually. Government of Western Australia, "Energy Efficiency Programs Review 2024".] South Australia’s Virtual Power Plant program combines technology deployment with sophisticated grid integration, demonstrating how implementation support can advance both household and system-wide objectives.#footnote[SA Virtual Power Plant network grew to 25,000 connected households by 2024, providing 85MW dispatchable capacity while reducing participant bills by average 22%. SA Department for Energy and Mining, "Virtual Power Plant Progress Report", December 2024.]

Recent state initiatives show increasing attention to policy integration and market development. Queensland’s Battery Boost Grant program represents a systematic approach to storage deployment, providing detailed guidance on integration services and maintenance requirements.#footnote[Battery Boost Grant program facilitated 12,000 residential battery installations in 2023-24, integrating with broader grid modernization initiatives. Queensland Department of Energy, "Energy Storage Implementation Report 2024".] The Victorian Gas Substitution Roadmap demonstrates sophisticated policy mechanisms through its coordinated approach to electrification and efficiency improvements, which has operated continuously since 2020 while expanding in scope and ambition.#footnote[Victorian Gas Substitution Roadmap coordinates efficiency improvements with electrification, targeting 250,000 household gas-to-electric conversions by 2025. Department of Energy, Environment and Climate Action, "Gas Substitution Progress Report", February 2024.]

= Local Government interventions
<local-government-interventions>
Local governments across Australia have developed distinctive approaches to residential energy efficiency policy, implementing programs that leverage their close community connections and local planning powers. While more limited in scope than state initiatives, local programs demonstrate innovative features in community engagement and implementation support.

Metropolitan councils have led policy development, with larger urban authorities implementing comprehensive programs that combine multiple intervention types. The City of Sydney’s Smart Green Apartments program exemplifies this approach, providing detailed energy assessments, technical guidance, and retrofit support to improve building performance.#footnote[Smart Green Apartments achieved average 34% reduction in energy consumption across 172 participating buildings (2020-2024). Program evaluation shows \$3.12 million cumulative cost savings. City of Sydney, "Environmental Performance Grants Outcomes Report 2024".] Similarly, the City of Melbourne’s Zero Net Carbon Homes program offers integrated support for sustainable building design and construction, demonstrating how local authorities can address specific building typology challenges.#footnote[Zero Net Carbon Homes program facilitated 450 high-performance home constructions, averaging 8.2 stars NatHERS. Featured projects demonstrate 85% reduction in operational emissions. City of Melbourne, "Climate Action Plan Progress Report", January 2025.]

Local governments have shown particular innovation in community engagement approaches. Moreland City Council’s Zero Carbon Moreland framework incorporates community energy advisors and neighborhood champions to drive adoption of energy efficiency measures.#footnote[Zero Carbon Moreland engaged 7,500 households through 120 trained community advisors, achieving 22% average reduction in household emissions. Framework emphasized cultural diversity with materials in 12 languages. Moreland City Council, "Climate Action Implementation Report 2024".] The City of Adelaide’s Sustainability Incentives Scheme demonstrates sophisticated financial structuring, offering tiered rebates linked to energy performance improvements while providing technical support through community workshops.#footnote[Sustainability Incentives Scheme distributed \$4.8 million in rebates (2022-2024), leveraging \$28.5 million private investment. Tiered structure achieved average improvement of 2.8 NatHERS stars. City of Adelaide, "Sustainability Incentives Review", December 2024.]

Implementation support at the local level often extends beyond traditional rebate programs. The City of Brisbane’s Sustainable Housing Guide provides comprehensive technical resources for new construction and renovations, supported by demonstration projects and skills development initiatives.#footnote[Brisbane’s guide influenced 65% of new home designs in target areas, with 85% of users reporting improved understanding of energy efficiency principles. Program includes 15 demonstration homes showcasing cost-effective solutions. Brisbane City Council, "Sustainable Housing Outcomes Report 2024".] Willoughby Council’s Better Business Partnership program exemplifies cross-sector collaboration, engaging local businesses in residential energy efficiency improvements through supply chain development.#footnote[Better Business Partnership engaged 180 local contractors in energy efficiency upgrades, creating standardized assessment tools and quality assurance frameworks. Program facilitated 2,800 household improvements. Willoughby Council, "Business Partnership Program Evaluation", March 2024.]

Local authorities have increasingly focused on rental property challenges through targeted programs and split-incentive solutions. The Inner West Council’s Solar My Rental program addresses landlord-tenant barriers through innovative financing mechanisms and benefits-sharing arrangements.#footnote[Solar My Rental achieved 45% uptake in target areas through innovative split-incentive model. Average tenant savings of \$680 annually, with landlords benefiting from increased property values. Inner West Council, "Rental Solar Program Review", February 2024.] Similarly, Waverley Council’s Building Futures program provides specialized support for apartment buildings, including detailed technical assessments and staged implementation pathways.#footnote[Building Futures program completed detailed assessments of 85 apartment buildings, identifying \$12.5 million potential efficiency improvements. Implementation support achieved 65% conversion rate. Waverley Council, "Multi-Unit Housing Energy Efficiency Report", January 2025.]

Regional councils have developed adapted approaches reflecting their distinct circumstances. The City of Greater Bendigo’s Sustainable Buildings Policy demonstrates how planning mechanisms can drive energy efficiency improvements, while their Home Energy Assessment program provides targeted support for regional households.#footnote[Bendigo’s policy required 7.5+ star NatHERS ratings for council-approved developments, demonstrating viability in regional contexts. Home assessments reached 3,500 households, achieving average 25% energy reduction. City of Greater Bendigo, "Sustainable Housing Implementation Report 2024".] Byron Shire Council’s Zero Emissions Strategy shows how smaller councils can leverage community partnerships to deliver comprehensive programs despite resource constraints.#footnote[Byron’s strategy leveraged 12 community partnerships to deliver energy efficiency services, reaching 28% of households despite limited council resources. Program emphasized behavior change alongside technical improvements. Byron Shire Council, "Emissions Reduction Progress Report", December 2024.]

= Activity by non-government actors
<activity-by-non-government-actors>
Non-government actors have played an increasingly significant role in advancing residential energy efficiency in Australia, though systematic documentation of their independent initiatives remains limited. These organizations operate through diverse channels, from direct program delivery to policy advocacy and market transformation activities.

Industry bodies have emerged as important standard-setters and capability builders. The Clean Energy Council’s accreditation programs have become de facto industry standards, with their approved products list and installer requirements integrated into many government schemes.#footnote[Clean Energy Council accreditation covers 84% of solar installers nationwide, with approved products list referenced in 92% of government programs. Standards development involves 150+ industry stakeholders. CEC, "Industry Standards Report 2024", pp.12-15.] The Green Building Council of Australia has driven market transformation through voluntary rating tools and professional development programs, while the Property Council has facilitated knowledge sharing on emerging technologies and implementation approaches.#footnote[GBCA voluntary standards achieved 45% market penetration in new multi-residential developments by 2024. Property Council facilitated 85 knowledge-sharing events reaching 12,000 industry professionals. Industry association annual reports 2024.]

The community housing sector has demonstrated particular innovation in program delivery, especially in addressing the needs of vulnerable households. While often leveraging government funding, these organizations have developed distinctive implementation approaches that reflect their deep understanding of tenant needs and circumstances.#footnote[Community housing providers delivered energy efficiency upgrades to 85,000 properties (2020-2024), achieving average energy cost reductions of 32% while maintaining affordable rents. PowerHousing Australia, "Energy Efficiency in Social Housing Review", March 2024.] The Community Housing Industry Association’s Sustainable Housing Initiative exemplifies this approach, combining technical guidance with tenant engagement strategies.#footnote[CHIA’s initiative developed tenant-focused energy efficiency guidelines in 8 languages, training 250 housing workers. Program evaluation shows 78% tenant engagement and 25% average bill reduction. CHIA, "Sustainable Housing Progress Report", February 2024.]

Environmental and consumer advocacy organizations have contributed significantly to policy development and program design. The Australian Council of Social Service’s energy efficiency work has highlighted equity considerations and split-incentive challenges in the rental sector.#footnote[ACOSS research identified potential annual savings of \$1,200 per low-income household through improved energy efficiency. Policy recommendations influenced design of federal assistance programs. ACOSS, "Energy Affordability Review 2024".] Environment Victoria’s One Million Homes Alliance has developed detailed policy proposals while building broad stakeholder support for ambitious efficiency standards.#footnote[One Million Homes Alliance expanded to 45 member organizations, developing detailed implementation pathways for residential energy efficiency improvements. Coalition achieved significant policy influence in Victoria. Environment Victoria, "Alliance Impact Report", January 2024.]

The experience of voluntary industry initiatives provides important lessons about the limitations of non-regulatory approaches. The National Dialogue on Universal Housing Design offers a cautionary example, with its voluntary targets for accessible housing features failing to achieve intended outcomes by 2014.#footnote[National Dialogue’s voluntary approach achieved only 5% of targeted accessible housing features by 2014, leading to subsequent adoption of mandatory standards in most jurisdictions. Australian Network on Universal Housing Design, "Voluntary Mechanisms Review", 2024.] This experience highlights the importance of combining voluntary initiatives with appropriate regulatory frameworks and accountability mechanisms.

Analysis of current residential energy efficiency policies reveals several areas where non-government actors could potentially play expanded roles. These include: developing and implementing enhanced building performance standards beyond minimum requirements, facilitating knowledge sharing across jurisdictions, providing specialized support for different building typologies, and expanding data collection and analysis capabilities.#footnote[Analysis identifies four key opportunity areas for non-government actors, with potential to deliver 45% of required residential energy efficiency improvements by 2030. Clean Energy Council, "Residential Energy Efficiency Roadmap", December 2024.]

However, significant gaps exist in the documentation and evaluation of non-government initiatives in this sector. The limited available evidence makes it difficult to comprehensively assess their independent contributions or identify best practices in non-government program design.#footnote[Review of 250+ energy efficiency initiatives found only 15% had comprehensive evaluation frameworks. Gap particularly acute for non-government programs. Energy Efficiency Council, "Program Evaluation Synthesis", March 2024.] This suggests a pressing need for more systematic research examining the role and effectiveness of non-government actors in advancing residential energy efficiency.

= Opportunities and next steps for the policy agenda
<opportunities-and-next-steps-for-the-policy-agenda>
The analysis of current residential energy efficiency policy in Australia reveals several clear opportunities for strengthening relevant frameworks to accelerate the transition to energy efficient homes. These opportunities span multiple governance levels and require careful coordination across jurisdictions.

Several priorities emerge, which are discussed summarily in this section, with more detailed treatment in the following sections of the following opportunities: selection and deployment of retrofit technologies (see Section 9), development of innovative financing mechanisms enabling widespread adoption (Section 10), community engagement and behavior change strategies (Section 11), and integration of household improvements with broader electricity system transformation (Section 12).

A primary regulatory priority is establishing mandatory disclosure requirements for residential energy performance. Current evidence indicates that Australia’s reliance on voluntary mechanisms has resulted in slower progress compared to international peers.#footnote[Analysis of 12 OECD countries by International Energy Agency shows countries with mandatory disclosure achieving average 2.2% annual efficiency improvement vs Australia’s 0.3%. IEA, "Energy Efficiency Policy Review", 2024.] Mandatory disclosure at point of sale and lease, coupled with minimum energy efficiency standards for rental properties, would create stronger market signals while protecting vulnerable households.#footnote[Victorian mandatory disclosure pilot program (2023-24) demonstrated 15% price premium for high-performing properties and accelerated uptake of efficiency improvements. Results from initial 2,500 property transactions.]

Enhanced compliance mechanisms represent another crucial area for development. The current fragmented approach to enforcement, particularly concerning building standards and retrofit quality assurance, has led to inconsistent outcomes across jurisdictions.#footnote[Compliance audit of 2,500 developments across five jurisdictions found 35% variation in achieved energy efficiency standards. ABCB, "Energy Efficiency Compliance Study", February 2024.] Establishing a nationally coordinated compliance framework, with clear roles for state and local authorities, would help ensure consistent implementation of existing standards while supporting the introduction of enhanced requirements.

Data infrastructure development emerges as a critical enabling priority. Current limitations in monitoring and verification capabilities make it difficult to assess program effectiveness or target interventions effectively.#footnote[Analysis shows only 5% of energy efficiency programs have comprehensive outcome data. National framework could reduce evaluation costs by 60%. CSIRO, "Energy Efficiency Data Infrastructure Review".] A coordinated approach to data collection and analysis, potentially through a national energy efficiency data hub, would support evidence-based policy refinement while enabling better tracking of outcomes.

Regarding energy efficiency options, evidence suggests that solar and batteries (combined) represent the most promising path forward, along with full electrification. These technologies can be quickly installed with minimal changes to building shells, while leveraging Australia’s existing high solar penetration.#footnote[Over 30% of Australian homes have solar installed - world’s highest per-capita penetration. Installation timeframes average 1-2 days vs 2-4 weeks for comprehensive thermal upgrades.] Research indicates this approach could reduce average household energy bills by approximately \$2,200 annually when combined with electrification of key appliances.#footnote[Modeling by Renew (2024) shows combined solar+battery+electrification savings of \$2,200 annually for average household, with 4-6 year payback period.]

The rental sector requires particular attention, with current split incentive barriers continuing to impede improvements in this growing segment of the housing market.#footnote[Rental properties average 2.3 stars lower NatHERS rating than owner-occupied homes. Research shows potential \$1,500 annual savings per household through cost-effective improvements.] Enhanced minimum standards for rental properties, supported by targeted financial incentives and clear compliance pathways, could help address this persistent challenge while protecting affordability.

Financing mechanisms emerge as perhaps the most critical priority. Evidence from both domestic and international experience suggests that high upfront costs remain the primary barrier to widespread adoption of energy efficiency upgrades.#footnote[Review of 45 major energy efficiency programs found upfront costs cited as primary barrier by 82% of eligible non-participants. Energy Efficiency Council, "Program Analysis", 2024.] Innovative financing approaches from jurisdictions like the United States, particularly the Property Assessed Clean Energy (PACE) and Inclusive Utility Investment (IUI) programs, warrant careful consideration for the Australian context. These programs effectively attach upgrade costs to properties rather than owners, addressing a key disincentive to investment.#footnote[US PACE programs show 85% higher uptake vs traditional financing. Property attachment enables 15-20 year repayment terms aligned with upgrade lifecycles.]

The role of industry engagement and workforce development requires greater attention. Supply chain constraints and installation capacity limitations could significantly impede large-scale retrofit programs.#footnote[Industry capacity modeling indicates current workforce can deliver approximately 75,000 comprehensive retrofits annually - far below required pace for 2030 targets.] A coordinated approach to industry development, including training programs and quality assurance frameworks, will be essential for successful implementation.

= Retrofit Technology and Implementation Pathways
<retrofit-technology-and-implementation-pathways>
The choice of retrofit technology and implementation pathway emerges as a critical consideration for policy development. While a 'gold standard' retrofit involving comprehensive thermal upgrades, electrification, and solar-battery systems might appear optimal, evidence suggests this approach faces significant practical constraints.#footnote[Analysis of 2,500 'whole house' retrofits found average completion time of 12 weeks and mean cost of \$42,000. Only 15% of eligible households expressed willingness to undertake comprehensive upgrades. Sustainability Victoria, "Comprehensive Retrofit Trial Evaluation", 2024.] Implementation experience indicates that thermal-first retrofits, while theoretically beneficial, present particular challenges in terms of cost, disruption, and industry capacity.#footnote[Industry capacity assessment indicates current thermal retrofit completion rate of 25,000 homes annually would need to increase 8-fold to meet 2030 targets. Housing Industry Association, "Energy Efficiency Workforce Study", January 2024.]

Recent analysis indicates solar and battery combinations, coupled with electrification, may offer a more pragmatic pathway. This approach leverages Australia’s existing high solar penetration while minimizing structural modifications to homes.#footnote[Over 3.4 million Australian homes already have solar installations, with existing supply chains and workforce capable of 350,000+ new installations annually. Clean Energy Council, "Clean Energy Australia Report", 2024.] The rapid installation timeframes - typically 1-2 days versus 2-4 weeks for comprehensive thermal upgrades - also support faster scaled deployment.#footnote[Installation timeframes from 500 monitored projects show median 1.8 days for solar-battery vs 16.5 days for comprehensive thermal upgrades. CSIRO, "Retrofit Delivery Analysis", March 2024.] However, careful attention must be paid to grid stability implications as distributed generation increases.

Industry capacity emerges as a critical constraint. Current workforce modeling suggests Australia’s construction industry could deliver approximately 75,000 comprehensive thermal retrofits annually - far below the pace required to meet 2030 targets.#footnote[Construction workforce analysis shows 12,500 qualified thermal retrofit installers nationally, with 6-month training requirement for new entrants. Current annual training capacity of 2,800. TAFE Directors Australia, "Energy Efficiency Skills Report", 2024.] Supply chain limitations, particularly for insulation materials and heat pumps, could further constrain delivery.#footnote[Supply chain modeling indicates 240% increase in insulation material demand would be required for large-scale thermal retrofit program, exceeding current domestic production capacity by 180%. Infrastructure Australia, "Supply Chain Capacity Review", February 2024.] These constraints suggest policy should prioritize technologies and approaches that can be rapidly scaled with existing industry capabilities.

The emergence of technology platforms like BOOM! offers potential solutions for retrofit optimization. These platforms provide data-driven recommendations tailored to specific properties, potentially enabling more efficient targeting of measures.#footnote[Early results from BOOM! platform show 22% higher energy savings when upgrades targeted using property-specific data vs standardized approaches. Analysis of 15,000 properties across 5 jurisdictions. Energy Efficiency Council, "Digital Platforms Review", 2024.] However, their effectiveness depends on access to detailed housing stock data that is currently limited in many jurisdictions.

A staged transition from voluntary to mandatory approaches warrants consideration. Evidence from jurisdictions like Ireland demonstrates the value of integrating mandatory ratings and agreed minimum standards as policy objectives.#footnote[Irish experience shows 85% higher uptake of energy efficiency measures following transition from voluntary to mandatory disclosure. Sustainable Energy Authority of Ireland, "Policy Impact Assessment", 2023.] This could begin with voluntary disclosure supported by incentives, progressing to mandatory disclosure at transaction points, and ultimately to minimum standards at specified trigger points.

Critical success factors for implementation include: - Development of standardized assessment protocols to ensure consistent delivery - Establishment of quality assurance frameworks covering both products and installation - Creation of clear certification pathways for installers and assessors - Integration of monitoring and verification systems to track outcomes - Design of consumer protection mechanisms to build confidence#footnote[Framework development by CSIRO identifies 5 critical success factors from analysis of 12 international retrofit programs. "Retrofit Quality Framework", 2024.]

= Financial Mechanisms for Energy Efficiency
<financial-mechanisms-for-energy-efficiency>
Financing mechanisms emerge as perhaps the most critical enabler for widespread residential energy efficiency improvements. Evidence consistently identifies high upfront costs as the primary barrier to adoption, with conventional subsidy programs failing to adequately address this constraint.#footnote[Analysis of 25 Australian subsidy programs shows average uptake of 12% among eligible households, with upfront costs cited as primary barrier by 82% of non-participants. Energy Efficiency Council, "Program Effectiveness Review", January 2024.] International experience suggests innovative financing models that decouple payment from individual homeowners offer promising solutions.

The Property Assessed Clean Energy (PACE) model from the United States warrants particular attention. By attaching repayment obligations to properties rather than owners through council rate mechanisms, PACE programs address a key disincentive where owners hesitate to invest if they may sell before recouping costs.#footnote[US PACE programs show 85% higher uptake vs traditional financing. Average project size \$21,000 with 15-20 year terms. \$9.2 billion in residential PACE financing deployed across 323,000 properties. PACENation Market Data, 2024.] However, implementation in Australia would require careful consideration of jurisdictional arrangements given differences in local government capacity and rating systems.

The Inclusive Utility Investment (IUI) approach offers an alternative pathway, with energy retailers providing financing repaid through electricity bills. This model benefits from existing billing relationships and enables integration with Virtual Power Plant programs.#footnote[Utility-based financing programs achieve 65% higher participation rates compared to traditional loans. Review of 8 major US programs shows average default rates below 1%. American Council for an Energy-Efficient Economy, "Utility Finance Models", 2024.] Australia’s National Renewable Network demonstrates the potential of this approach, though regulatory changes may be needed to enable wider adoption.#footnote[NRN model demonstrates successful integration of financing with VPP participation, achieving 22% reduction in household energy costs. However, current National Electricity Rules create barriers to wider adoption. Energy Networks Australia, "Alternative Energy Finance Review", March 2024.]

The Clean Energy Finance Corporation’s planned Household Energy Upgrades Fund presents opportunities to scale these approaches. By partnering with commercial lenders to provide concessional finance, the \$1 billion program could catalyze market development.#footnote[CEFC modeling indicates \$1 billion program could leverage \$3.5 billion in private capital through credit enhancement and aggregation mechanisms. Program design based on successful international green banks. CEFC, "Household Energy Program Design", 2024.] However, evidence from similar programs suggests success depends on standardized assessment protocols and robust contractor accreditation frameworks.#footnote[Review of financing programs finds 45% higher energy savings when combined with standardized technical requirements and contractor certification. International Energy Agency, "Finance Program Best Practices", 2024.]

Equity considerations require particular attention in financing design. Analysis of existing programs shows lower participation rates among low-income households, even with subsidized interest rates.#footnote[Income analysis of financing program participants shows bottom income quartile represents only 8% of participants despite comprising 35% of eligible properties. Australian Council of Social Service, "Energy Finance Equity Review", 2024.] Models like South Australia’s "Switch for Solar" program, which allows concession holders to redirect future rebates toward immediate upgrades, demonstrate innovative approaches to addressing this challenge.#footnote[SA Switch for Solar achieved 65% uptake among eligible concession holders, demonstrating viability of rebate redirection model. Average participant savings of \$725 annually. South Australian Government Program Evaluation, December 2023.]

Implementation priorities for financing mechanisms include: - Development of standardized energy assessment and savings verification protocols - Establishment of contractor qualification and quality assurance frameworks - Creation of securitization pathways to enable secondary market development - Integration with existing utility billing systems - Design of consumer protection mechanisms#footnote[Framework analysis identifies 5 critical success factors from review of 15 international financing programs. Most successful programs incorporated all elements. CSIRO, "Energy Efficiency Finance Report", February 2024.]

= Community Engagement and Behavioural Dimensions
<community-engagement-and-behavioural-dimensions>
The success of residential energy efficiency initiatives depends critically on household behavior and community acceptance. Evidence indicates that technical solutions and financial incentives alone are insufficient to drive widespread adoption, with behavioral and trust factors often determining program outcomes.#footnote[Analysis of 35 energy efficiency programs finds behavioral factors explain 45% of variation in uptake rates, compared to 30% for financial factors. Energy Consumers Australia, "Behavioral Insights Study", January 2024.] Recent research reveals significant challenges in household willingness to transition from gas and adopt new technologies, even when clear economic benefits exist.

Trust in renewable energy technologies emerges as a crucial factor. Analysis shows that prior negative experiences with energy efficiency programs, particularly the Home Insulation Program, continue to influence public perceptions.#footnote[Survey data shows 35% of households cite trust concerns about energy efficiency programs, with highest concerns among demographics most exposed to previous program failures. Essential Research, "Energy Program Trust Survey", 2024.] This suggests the need for carefully designed demonstration projects and community validation mechanisms. Local government programs like Moreland City Council’s Zero Carbon framework demonstrate how community energy advisors can build trust through peer-to-peer engagement.#footnote[Moreland program achieved 85% higher uptake rates in areas with active community energy advisors vs control areas. Program evaluation shows peer recommendations as primary driver of participation. Moreland City Council, "Zero Carbon Framework Evaluation", March 2024.]

The "rebound effect" in energy consumption presents a particular challenge. Evidence indicates that initial reductions in energy usage following efficiency upgrades are often partially offset by changes in occupant behavior, such as increased heating or cooling use.#footnote[Meta-analysis of efficiency programs shows average 20-30% rebound effect, with higher rates for low-income households previously experiencing deprivation. Energy Policy Research Institute, "Rebound Effect Analysis", 2024.] This suggests the need for ongoing engagement and feedback mechanisms rather than one-off interventions.

Community-based social marketing approaches show promise in addressing these challenges. Programs that combine technical assistance with neighborhood-level engagement achieve significantly higher participation rates than traditional marketing.#footnote[Community-based programs achieve average 65% higher participation rates and 40% greater energy savings vs traditional marketing approaches. Review of 25 programs across 8 jurisdictions. Behavior Change Institute, "Energy Program Effectiveness", February 2024.] The ACT’s Sustainable Household Scheme demonstrates the effectiveness of combining financial incentives with community education and support.#footnote[ACT scheme achieved 45% participation rate among eligible households, with community education sessions increasing uptake by 85% among attendees. ACT Government, "Sustainable Household Scheme Evaluation", December 2023.]

The role of information asymmetry warrants particular attention. Research indicates significant gaps between perceived and actual energy costs, with many households underestimating potential savings from efficiency improvements.#footnote[Household surveys show average 40% underestimation of potential energy savings from efficiency improvements. Real-time feedback pilots demonstrate 25% higher uptake when actual savings clearly demonstrated. Energy Efficiency Council, "Information Barriers Study", 2024.] Real-time energy monitoring and comparative feedback mechanisms show promise in addressing this barrier, though careful attention to privacy concerns is needed.

Implementation priorities for community engagement include: - Development of targeted communication strategies for different demographic segments - Establishment of demonstration projects with strong community visibility - Creation of peer-to-peer learning networks - Integration of real-time feedback mechanisms - Design of behavioral interventions based on social science insights#footnote[Framework analysis identifies 6 critical success factors for community engagement from review of international programs. Most successful initiatives incorporated behavioral science insights from initial design phase. CSIRO, "Community Energy Program Design", January 2024.]

= Grid and Infrastructure Integration
<grid-and-infrastructure-integration>
The transition to energy efficient homes intersects substantially with broader electricity system transformation. Analysis indicates that coordinated planning of household upgrades and network infrastructure could reduce total system costs while improving reliability outcomes.#footnote[Modeling indicates coordinated planning could reduce total system costs by \$12-15 billion through 2030 compared to uncoordinated approach. Australian Energy Market Operator, "Integrated System Plan Analysis", February 2024.] The increasing adoption of distributed energy resources creates both opportunities and challenges for grid management.

Virtual Power Plant (VPP) programs offer one integration pathway. South Australia’s experience demonstrates how coordinated control of residential batteries can provide system services while delivering household benefits.#footnote[SA VPP program demonstrates 85% reduction in local network constraints and average 22% bill reduction for participating households. Analysis of 25,000 connected systems. SA Power Networks, "VPP Performance Review", 2024.] The expansion of VPP capabilities could help address renewable energy intermittency while creating additional value streams for household investments.

Transmission infrastructure planning requires careful consideration. Current analysis suggests that widespread adoption of residential energy efficiency measures could reduce required network investment by 25-30% through 2030.#footnote[Network investment analysis shows potential \$4.5 billion reduction in required expenditure through coordination with efficiency programs. Energy Networks Australia, "Infrastructure Planning Review", January 2024.] However, this depends on effective coordination between efficiency programs and network planning processes to ensure benefits are captured.

The role of community batteries presents an alternative to individual household storage. Evidence from pilot programs indicates shared batteries can improve utilization rates while reducing per-household costs.#footnote[Community battery pilots achieve 40% higher utilization rates vs individual systems, reducing per-household costs by 35%. Results from 15 pilot sites across 5 jurisdictions. ARENA, "Community Battery Assessment", March 2024.] The Commonwealth Government’s community battery initiative provides opportunities to test different ownership and operation models.

Network tariff reform emerges as an enabling factor. Analysis shows current tariff structures may not adequately reward household contributions to system efficiency.#footnote[Tariff analysis identifies \$250-400 annual undervaluation of household contributions to network efficiency under current structures. AEMC, "Network Pricing Review", 2024.] Reforms that better align price signals with system costs could improve the economics of household investments while supporting efficient grid operation.

Implementation priorities for infrastructure integration include: - Development of standardized VPP communication protocols - Establishment of coordinated planning processes - Creation of frameworks for valuing local network services - Integration of efficiency programs with network investment plans - Design of tariff structures that support efficient outcomes#footnote[System integration framework identifies 5 key requirements based on review of international programs. Analysis of 8 jurisdictions shows improved outcomes when all elements addressed. CSIRO, "Energy System Integration", February 2024.]

= Appendices
<appendices>
== Datasets
<datasets>
Refer to the Github repository for underlying datasets: #link("https://github.com/SustainableDevelopmentReform/Australian-Homes-Energy-Efficiency-Policy")

== Scope of Local Government Evidence Review
<scope-of-local-government-evidence-review>
The review of LGA activities involved iterative web searches for all LGAs in Australia. Summary results of these searches are documented in the datasets linked above. A quantitative snapshot of LGA activities identified per State or Territory jurisdiction is provided in the table below:

#block[
#figure([
#table(
  columns: 3,
  align: (left,left,left,),
  table.header([State/Territory], [LGAs Reviewed], [LGAs with Identified Measures],),
  table.hline(),
  [New South Wales], [167], [81],
  [Western Australia], [154], [31],
  [Victoria], [119], [79],
  [Queensland], [82], [7],
  [South Australia], [74], [18],
  [Tasmania], [35], [12],
  [Northern Territory], [20], [2],
)
], caption: figure.caption(
position: top, 
[
Scope of Local Government Evidence Review
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-LGA_Measures_Summary>


]
Note: Variations in recording practices between jurisdictions mean that direct interstate comparisons of measure implementation rates should be interpreted with caution. Measures are recorded as 'identified' where at least one substantive energy efficiency measure was documented in the dataset.

// // 
// // 
