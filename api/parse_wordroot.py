import json
from pathlib import Path


wordroot_file = Path(Path(__file__).parent.absolute() / 'db/wordroot.txt')

class WordRoot():
    wordroot = dict()

    def __init__(self) -> None:
        with wordroot_file.open() as f:
            self.wordroot= json.load(f)
        print(f"wordroot.txt including {len(self.wordroot.keys())} roots.")

    def which_root_with_number_suffix(self) -> set():
        '''
        找出带有数字后缀的词根词缀
        '''
        for root in self.wordroot.keys():
            sub_root:str = str(root).split(',')
            for sr in sub_root:
                sr = sr.strip()
                if sr[-1].isdigit():
                    print(sr)
    
    def mark_all_root_in_a_word(self, word:str) -> dict:
        '''
        将当前单词所包含的词根词缀标注出来
        通过查表方式匹配，但一个单词的字母组合不一定有含意，容易误读
        '''
        pass

    def how_wordroot_cover_ielts(self):
        '''
        比较词根库文件跟四六雅思单词表之间集合的交集大小，占各自的比例
        '''
        vocab_file = Path(Path(__file__).parent.absolute() / 'db/vocab.json')
        with vocab_file.open() as f:
            data: dict = json.load(f)
        # print(data.keys())
        ielts46: set = set(data['JUNIOR']).union(set(data['SENIOR'])).union(set(data['IELTS']))
        print(f'vocab.json including {len(ielts46)} words.')

        examples: set = set()
        for _,v in self.wordroot.items():
            j = list(dict(v).get('example'))
            i = set(j)
            examples = examples.union(i)
        print(f"wordroot.txt including {len(examples)} example word.")

        # 每一个example word是不是都在vocab中？False
        # print(ielts46.issubset(examples))

        # 有多少不在高中+雅思单词表中？4601
        # print(len(examples.difference(ielts46)))
        
        # 共同的交集是多少？能占高中+雅思单词表的多大比例？
        # print(len(examples.intersection(ielts46)) / len(ielts46))

        # 主观感受一下任意敲下一个单词，会查到这个词的词根词缀的可能性

if __name__ == '__main__':
    w = WordRoot()
    w.how_wordroot_cover_ielts()


