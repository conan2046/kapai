#include "g_ini_file.h"
#include <sstream>

using namespace std;

namespace {
static string trim_copy(const string &s)
{
	size_t b = s.find_first_not_of(" \t\r\n");
	if(b == string::npos)
		return "";
	size_t e = s.find_last_not_of(" \t\r\n");
	return s.substr(b, e - b + 1);
}
}

namespace gyu {
namespace util {

CIniFile::CIniFile(void) {}
CIniFile::~CIniFile(void) {}

bool CIniFile::Load(string FileName, vector<Record>& content)
{
	ifstream in(FileName.c_str());
	if(!in.is_open())
		return false;

	string section;
	string pendingComments;
	string line;
	while(getline(in, line))
	{
		string raw = line;
		string s = trim_copy(line);
		if(s.empty())
			continue;
		if(s[0] == '#' || s[0] == ';')
		{
			pendingComments += raw;
			pendingComments += "\n";
			continue;
		}
		if(s[0] == '[' && s[s.size() - 1] == ']')
		{
			section = trim_copy(s.substr(1, s.size() - 2));
			continue;
		}

		size_t eq = s.find('=');
		if(eq == string::npos)
			continue;
		Record rec;
		rec.Comments = pendingComments;
		rec.Commented = 0;
		rec.Section = section;
		rec.Key = trim_copy(s.substr(0, eq));
		rec.Value = trim_copy(s.substr(eq + 1));
		content.push_back(rec);
		pendingComments.clear();
	}
	return true;
}

bool CIniFile::Save(string FileName, vector<Record>& content)
{
	ofstream out(FileName.c_str(), ios::trunc);
	if(!out.is_open())
		return false;
	string current;
	for(size_t i = 0; i < content.size(); ++i)
	{
		if(content[i].Section != current)
		{
			current = content[i].Section;
			out << "[" << current << "]\n";
		}
		if(!content[i].Comments.empty())
			out << content[i].Comments;
		if(content[i].Commented)
			out << content[i].Commented;
		out << content[i].Key << "=" << content[i].Value << "\n";
	}
	return true;
}

string CIniFile::GetValue(string KeyName, string SectionName, string FileName)
{
	vector<Record> records;
	if(!Load(FileName, records))
		return "";
	for(size_t i = 0; i < records.size(); ++i)
	{
		if(records[i].Section == SectionName && records[i].Key == KeyName)
			return records[i].Value;
	}
	return "";
}

bool CIniFile::SetValue(string KeyName, string Value, string SectionName, string FileName)
{
	vector<Record> records;
	Load(FileName, records);
	for(size_t i = 0; i < records.size(); ++i)
	{
		if(records[i].Section == SectionName && records[i].Key == KeyName)
		{
			records[i].Value = Value;
			return Save(FileName, records);
		}
	}
	Record rec;
	rec.Commented = 0;
	rec.Section = SectionName;
	rec.Key = KeyName;
	rec.Value = Value;
	records.push_back(rec);
	return Save(FileName, records);
}

bool CIniFile::RecordExists(string KeyName, string SectionName, string FileName)
{
	return !GetValue(KeyName, SectionName, FileName).empty();
}

vector<CIniFile::Record> CIniFile::GetRecord(string KeyName, string SectionName, string FileName)
{
	vector<Record> records, ret;
	Load(FileName, records);
	for(size_t i = 0; i < records.size(); ++i)
		if(records[i].Section == SectionName && records[i].Key == KeyName)
			ret.push_back(records[i]);
	return ret;
}

vector<CIniFile::Record> CIniFile::GetSection(string SectionName, string FileName)
{
	vector<Record> records, ret;
	Load(FileName, records);
	for(size_t i = 0; i < records.size(); ++i)
		if(records[i].Section == SectionName)
			ret.push_back(records[i]);
	return ret;
}

vector<CIniFile::Record> CIniFile::GetSections(string FileName)
{
	vector<Record> records;
	Load(FileName, records);
	return records;
}

vector<string> CIniFile::GetSectionNames(string FileName)
{
	vector<Record> records;
	vector<string> names;
	Load(FileName, records);
	for(size_t i = 0; i < records.size(); ++i)
	{
		bool exists = false;
		for(size_t j = 0; j < names.size(); ++j)
			if(names[j] == records[i].Section)
				exists = true;
		if(!exists)
			names.push_back(records[i].Section);
	}
	return names;
}

bool CIniFile::SectionExists(string SectionName, string FileName)
{
	vector<string> names = GetSectionNames(FileName);
	for(size_t i = 0; i < names.size(); ++i)
		if(names[i] == SectionName)
			return true;
	return false;
}

string CIniFile::Content(string FileName)
{
	ifstream in(FileName.c_str(), ios::binary);
	if(!in.is_open())
		return "";
	stringstream ss;
	ss << in.rdbuf();
	return ss.str();
}

bool CIniFile::Create(string FileName)
{
	ofstream out(FileName.c_str(), ios::app);
	return out.is_open();
}

bool CIniFile::AddSection(string SectionName, string FileName)
{
	if(SectionExists(SectionName, FileName))
		return true;
	ofstream out(FileName.c_str(), ios::app);
	if(!out.is_open())
		return false;
	out << "[" << SectionName << "]\n";
	return true;
}

bool CIniFile::DeleteRecord(string KeyName, string SectionName, string FileName)
{
	vector<Record> records;
	Load(FileName, records);
	for(vector<Record>::iterator it = records.begin(); it != records.end(); ++it)
	{
		if(it->Section == SectionName && it->Key == KeyName)
		{
			records.erase(it);
			return Save(FileName, records);
		}
	}
	return false;
}

bool CIniFile::DeleteSection(string SectionName, string FileName)
{
	vector<Record> records;
	Load(FileName, records);
	for(vector<Record>::iterator it = records.begin(); it != records.end();)
	{
		if(it->Section == SectionName)
			it = records.erase(it);
		else
			++it;
	}
	return Save(FileName, records);
}

bool CIniFile::RenameSection(string OldSectionName, string NewSectionName, string FileName)
{
	vector<Record> records;
	Load(FileName, records);
	for(size_t i = 0; i < records.size(); ++i)
		if(records[i].Section == OldSectionName)
			records[i].Section = NewSectionName;
	return Save(FileName, records);
}

bool CIniFile::CommentRecord(CommentChar, string, string, string) { return false; }
bool CIniFile::CommentSection(char, string, string) { return false; }
bool CIniFile::SetRecordComments(string, string, string, string) { return false; }
bool CIniFile::SetSectionComments(string, string, string) { return false; }
bool CIniFile::Sort(string, bool) { return true; }
bool CIniFile::UnCommentRecord(string, string, string) { return false; }
bool CIniFile::UnCommentSection(string, string) { return false; }

}
}
