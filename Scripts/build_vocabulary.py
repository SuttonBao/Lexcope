#!/usr/bin/env python3
"""Build the small, fully annotated starter library; assert official list membership."""
import csv
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
# Original learner content. The selected headwords are checked against official sources.
# term ; IPA ; meaning ; English definition ; example ; translation ; collocations ; family
DAILY = '''remember; rɪˈmembə; 记得；记住; To keep something in your mind or bring it back to mind.; I remember our first conversation.; 我记得我们第一次交谈。; remember clearly|remember to call; memory|memorable
opportunity; ˌɒpəˈtjuːnəti; 机会; A situation that makes it possible to do something.; This course is an opportunity to practise speaking.; 这门课是练习口语的机会。; a good opportunity|take an opportunity; opportunities
available; əˈveɪləbl; 可获得的；有空的; Ready for someone to use or able to meet someone.; Are you available on Friday?; 你星期五有空吗？; available online|readily available; availability|unavailable
approach; əˈprəʊtʃ; 方法；接近; A way of dealing with a task or problem.; We need a different approach to this problem.; 我们需要用不同的方法解决这个问题。; a practical approach|approach a problem; approachable
benefit; ˈbenɪfɪt; 好处；使受益; A helpful result or something that improves a situation.; Regular reading has many benefits.; 经常阅读有很多好处。; health benefits|benefit from; beneficial
improve; ɪmˈpruːv; 改善；提高; To become better or make something better.; My listening has improved this month.; 这个月我的听力提高了。; improve gradually|improve performance; improvement
essential; ɪˈsenʃl; 必不可少的; Needed for something to work or happen.; Sleep is essential for learning.; 睡眠对学习必不可少。; essential skills|essential for; essentially
 environment; ɪnˈvaɪrənmənt; 环境; The conditions or natural surroundings in which we live.; Plants need the right environment to grow.; 植物需要合适的环境才能生长。; natural environment|protect the environment; environmental|environmentally
knowledge; ˈnɒlɪdʒ; 知识；了解; Information and understanding gained through learning or experience.; She has a good knowledge of local history.; 她很了解当地历史。; gain knowledge|practical knowledge; knowledgeable
achieve; əˈtʃiːv; 达成；取得; To succeed in doing something after effort.; Small daily steps help us achieve our goals.; 每天迈出的小步帮助我们实现目标。; achieve a goal|achieve success; achievement|achievable
experience; ɪkˈspɪəriəns; 经历；经验; Knowledge gained by doing things or an event that happens to you.; The job gave me useful experience.; 这份工作给了我有用的经验。; work experience|gain experience; experienced
reliable; rɪˈlaɪəbl; 可靠的; Able to be trusted to work well or do what is expected.; We need reliable information before deciding.; 我们需要可靠的信息再作决定。; a reliable source|reliable service; reliability|rely
appointment; əˈpɔɪntmənt; 预约；约定; An arrangement to meet someone at a particular time.; I have an appointment at ten.; 我十点有一个预约。; book an appointment|make an appointment; appoint
choice; tʃɔɪs; 选择；可选项; The act of selecting something or an option you can select.; You have a choice of two courses.; 你可以从两门课中选一门。; make a choice|a wide choice; choose|chosen
journey; ˈdʒɜːni; 旅程; A trip from one place to another.; The train journey took two hours.; 这趟火车旅程花了两小时。; a long journey|begin a journey; journeys
purchase; ˈpɜːtʃəs; 购买；购买的东西; To buy something, or something you have bought.; You can purchase tickets at the station.; 你可以在车站买票。; make a purchase|purchase online; purchaser
recommend; ˌrekəˈmend; 推荐；建议; To suggest that something is useful or worth doing.; Can you recommend a book for beginners?; 你能推荐一本适合初学者的书吗？; highly recommend|recommend a course; recommendation
prefer; prɪˈfɜː; 更喜欢; To like or want one thing more than another.; I prefer studying in the morning.; 我更喜欢在早晨学习。; prefer to do|prefer one to another; preference|preferable
arrange; əˈreɪndʒ; 安排；整理; To make plans for something or put things in order.; Let's arrange a time to meet.; 我们安排一个见面的时间吧。; arrange a meeting|arrange in order; arrangement
borrow; ˈbɒrəʊ; 借入; To use something belonging to someone else and return it later.; May I borrow your dictionary?; 我可以借用你的词典吗？; borrow a book|borrow from; borrower
return; rɪˈtɜːn; 返回；归还; To go back or give something back.; Please return the book next week.; 请下周归还这本书。; return home|return a book; returning
 afford; əˈfɔːd; 负担得起; To have enough money or time for something.; We can afford a short holiday this year.; 今年我们负担得起一次短途假期。; afford to buy|can afford; affordable|affordability
community; kəˈmjuːnəti; 社区；群体; People who live in one area or share an interest.; The library is important to our community.; 图书馆对我们社区很重要。; local community|community centre; communities
habit; ˈhæbɪt; 习惯; Something you do regularly, often without thinking.; Reviewing words has become a daily habit.; 复习单词已经成了每天的习惯。; form a habit|a daily habit; habitual'''
ACADEMIC = '''allocate; ˈæləkeɪt; 分配; To decide how to share time, money, or other resources.; The team allocated more time to testing.; 团队分配了更多时间用于测试。; allocate resources|allocate time; allocation
absorb; əbˈzɔːb; 吸收；理解; To take in a substance or information.; Dry soil absorbs water quickly.; 干燥的土壤很快就吸收了水。; absorb water|absorb information; absorption|absorbent
accumulate; əˈkjuːmjəleɪt; 积累; To gradually collect or increase over time.; Evidence accumulated over several years.; 证据在数年间逐渐积累。; accumulate evidence|accumulate wealth; accumulation
accuracy; ˈækjərəsi; 准确性; The degree to which something is correct or exact.; Check the accuracy of the measurements.; 检查测量结果的准确性。; improve accuracy|measurement accuracy; accurate|accurately
adjacent; əˈdʒeɪsnt; 相邻的; Next to something or very close to it.; The laboratory is adjacent to the library.; 实验室紧挨着图书馆。; adjacent to|adjacent buildings; adjacency
agriculture; ˈæɡrɪkʌltʃə; 农业; The work of growing crops and raising animals for food.; Rainfall affects agriculture in this region.; 降雨影响这一地区的农业。; sustainable agriculture|agricultural land; agricultural
analogy; əˈnælədʒi; 类比; A comparison used to explain a similarity between different things.; She used an analogy to explain the process.; 她用一个类比来解释这个过程。; draw an analogy|an analogy between; analogous
arbitrary; ˈɑːbɪtrəri; 任意的；缺乏明确依据的; Based on a choice rather than a clear rule or reason.; The limit seemed arbitrary.; 这个限制似乎缺乏明确依据。; an arbitrary decision|an arbitrary limit; arbitrarily
artificial; ˌɑːtɪˈfɪʃl; 人工的；人造的; Made by people rather than occurring naturally.; The room has artificial lighting.; 这个房间使用人工照明。; artificial intelligence|artificial light; artificially
biodiversity; ˌbaɪəʊdaɪˈvɜːsəti; 生物多样性; The variety of living things in a place.; Forest loss threatens biodiversity.; 森林减少威胁着生物多样性。; protect biodiversity|biodiversity loss; diverse|diversity
cognitive; ˈkɒɡnətɪv; 认知的; Related to thinking, learning, and understanding.; The study examined cognitive development.; 这项研究考察了认知发展。; cognitive skills|cognitive development; cognition
coherent; kəʊˈhɪərənt; 连贯的；条理清楚的; Clear and logically connected so that it is easy to understand.; Present your argument in a coherent order.; 按照连贯的顺序陈述你的论点。; a coherent argument|a coherent explanation; coherence|coherently
compensate; ˈkɒmpenseɪt; 补偿；弥补; To make up for a loss or an unwanted effect.; Extra practice can compensate for limited experience.; 更多练习可以弥补经验不足。; compensate for|compensate workers; compensation
consensus; kənˈsensəs; 共识; General agreement among a group of people.; The committee reached a consensus.; 委员会达成了共识。; reach a consensus|a broad consensus; consensual
conservation; ˌkɒnsəˈveɪʃn; 保护；节约; The protection of nature or the careful use of resources.; Water conservation is important during droughts.; 干旱期间节约用水很重要。; wildlife conservation|energy conservation; conserve|conservationist
contradict; ˌkɒntrəˈdɪkt; 与……矛盾；反驳; To state the opposite of something or show it cannot be true.; The new results contradict the earlier report.; 新结果与之前的报告相矛盾。; contradict a claim|contradict the evidence; contradiction|contradictory
correlate; ˈkɒrəleɪt; 相关联; To have a relationship in which things tend to change together.; The researchers asked whether the two measures correlate.; 研究人员探究了这两项指标是否相关。; correlate with|strongly correlate; correlation
empirical; ɪmˈpɪrɪkl; 基于观察或实验的；实证的; Based on observations or experiments rather than theory alone.; The theory needs empirical support.; 这个理论需要实证支持。; empirical evidence|empirical research; empirically
explicit; ɪkˈsplɪsɪt; 明确的; Stated clearly and directly.; The instructions gave explicit examples.; 说明中给出了明确的例子。; explicit instructions|make explicit; explicitly
facilitate; fəˈsɪlɪteɪt; 促进；使更容易; To make an action or process easier.; Clear diagrams facilitate understanding.; 清晰的图表有助于理解。; facilitate learning|facilitate communication; facilitation|facilitator
inference; ˈɪnfərəns; 推论；推断; A conclusion drawn from evidence and reasoning.; The inference was based on limited evidence.; 这个推论建立在有限的证据上。; draw an inference|statistical inference; infer
methodology; ˌmeθəˈdɒlədʒi; 方法论；研究方法体系; The system of methods used in a field or study.; The paper describes the research methodology.; 论文描述了研究方法体系。; research methodology|a clear methodology; methodological
quantitative; ˈkwɒntɪtətɪv; 定量的; Related to amounts that can be counted or measured.; The team collected quantitative data.; 团队收集了定量数据。; quantitative analysis|quantitative data; quantity|quantify
qualitative; ˈkwɒlɪtətɪv; 定性的; Related to qualities or descriptions rather than numerical amounts.; Interviews provided qualitative evidence.; 访谈提供了定性证据。; qualitative research|qualitative data; quality'''
PHRASES = '''in advance; ɪn ədˈvɑːns; 提前; Before the time when something happens.; Please book your ticket in advance.; 请提前订票。; book in advance|pay in advance; advance
on behalf of; ɒn bɪˈhɑːf əv; 代表；为了……的利益; Acting for another person or group.; I am writing on behalf of our team.; 我代表我们团队写信。; speak on behalf of|act on behalf of; behalf
keep in mind; kiːp ɪn maɪnd; 记住；考虑到; To remember a fact while thinking about something.; Keep in mind that the library closes at six.; 请记住图书馆六点关门。; keep this in mind|keep in mind that; mind
take part in; teɪk pɑːt ɪn; 参加; To join others in an activity.; Many students took part in the discussion.; 许多学生参加了讨论。; take part in a discussion|take part in an event; participant|participate
as a result; əz ə rɪˈzʌlt; 因此；结果; Used to introduce what happened because of something else.; It rained all night. As a result, the road flooded.; 雨下了一夜，因此道路被淹了。; as a result of|as a direct result; result
in terms of; ɪn tɜːmz əv; 就……而言; Used to describe the particular aspect being considered.; Compare the options in terms of cost.; 从成本方面比较这些选项。; in terms of cost|in terms of quality; term
make sense; meɪk sens; 有道理；可以理解; To be understandable or reasonable.; Your explanation makes sense.; 你的解释很有道理。; make sense of|make perfect sense; sense|sensible
take into account; teɪk ˈɪntə əˈkaʊnt; 考虑到; To consider something when making a decision.; Take travel time into account.; 要把路上花的时间考虑进去。; take costs into account|take differences into account; account
from time to time; frəm taɪm tə taɪm; 偶尔；不时; Sometimes, but not regularly.; We meet for coffee from time to time.; 我们偶尔见面喝咖啡。; visit from time to time|check from time to time; time
look forward to; lʊk ˈfɔːwəd tə; 期待; To feel pleased about something that will happen.; I look forward to hearing from you.; 我期待收到你的来信。; look forward to meeting|look forward to a visit; forward
by contrast; baɪ ˈkɒntrɑːst; 相比之下; Used to show how two things are different.; The first task was simple. By contrast, the second was difficult.; 第一个任务很简单，相比之下，第二个很难。; by contrast with|in contrast; contrast|contrasting
in the long run; ɪn ðə lɒŋ rʌn; 从长远来看; Over a long period rather than immediately.; Regular practice helps in the long run.; 长期来看，经常练习会有帮助。; benefit in the long run|save in the long run; long'''

def parse(rows, source):
    result = []
    for line in rows.splitlines():
        term, ipa, meaning, definition, example, zh, collocations, family = map(str.strip, line.split(';'))
        result.append(dict(term=term, ipa=f'/{ipa}/', meaning=meaning, definition=definition,
                           examples=[dict(english=example, chinese=zh)], etymology=None,
                           collocations=collocations.split('|'), family=family.split('|'), source=source))
    return result

daily = parse(DAILY, 'NGSL 1.2 选词 · Lexcope 学习释义 · CC BY-SA 4.0')
academic = parse(ACADEMIC, 'NAWL 1.2 选词 · Lexcope 学习释义 · CC BY-SA 4.0')
phrases = parse(PHRASES, 'Lexcope 原创生活短语 · CC BY-SA 4.0')
ngsl = {r['Lemma'].lower() for r in csv.DictReader((root/'docs/sources/NGSL_12_stats.csv').open())}
nawl = set((root/'docs/sources/NAWL_12_alphabetized_description.txt').read_text().splitlines()[6:])
assert {w['term'] for w in daily} <= ngsl
assert {w['term'] for w in academic} <= nawl

# Transparent word-building notes, not invented historical origins.
notes = {
    'available': '构词提示：avail + 后缀 -able；-able 常表示“能够……的”。',
    'reliable': '构词提示：rely 变 y 为 i 后接 -able；相关名词为 reliability。',
    'improve': '词族提示：improve 加 -ment 构成名词 improvement。此处不推断历史词源。',
    'achievement': '词族提示：achieve + -ment。',
    'appointment': '构词提示：appoint + -ment；-ment 常构成表示行为或结果的名词。',
    'biodiversity': '构词提示：bio-（生命、生物）+ diversity（多样性）。',
    'accuracy': '词族提示：形容词 accurate 对应名词 accuracy 和副词 accurately。',
    'conservation': '词族提示：动词 conserve 对应名词 conservation。',
    'quantitative': '词族提示：与 quantity（数量）、quantify（量化）一起记忆。',
    'qualitative': '词族提示：与 quality（性质、质量）一起记忆。',
}
for word in daily + academic:
    word['etymology'] = notes.get(word['term'])

def deck(id, title, subtitle, words, source):
    return dict(id=id, title=title, subtitle=subtitle, wordIDs=[w['term'].lower() for w in words], source=source, isBuiltIn=True)
content = dict(words=daily + academic + phrases, decks=[
    deck('ngsl-starter', '生活核心词', 'NGSL 1.2 · 24 个入门选词', daily, 'Browne, Culligan & Phillips · NGSL 1.2 · CC BY-SA 4.0'),
    deck('pte-starter', 'PTE 学术入门', 'NAWL 1.2 · 16 个备考选词 · 非官方词库', academic[:16], 'NAWL 1.2 摘选，Lexcope 编排 · CC BY-SA 4.0'),
    deck('ielts-starter', 'IELTS 学术入门', 'NAWL 1.2 · 16 个备考选词 · 非官方词库', academic[8:], 'NAWL 1.2 摘选，Lexcope 编排 · CC BY-SA 4.0'),
    deck('phrases-starter', '生活常用短语', '12 个日常表达', phrases, 'Lexcope 原创编写 · CC BY-SA 4.0'),
])
(root/'Sources/LexcopeCore/Resources/vocabulary.json').write_text(json.dumps(content, ensure_ascii=False, indent=2)+'\n')
print(f'Validated {len(content["words"])} entries in {len(content["decks"])} decks.')
