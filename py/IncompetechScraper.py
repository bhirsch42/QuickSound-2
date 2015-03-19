import urllib2
import json
import os.path
from bs4 import BeautifulSoup

keywords = ['Action', 'Aggressive', 'Bouncy', 'Bright',
	'Calming', 'Dark', 'Driving', 'Eerie', 'Epic',
	'Grooving', 'Humorous', 'Intense', 'Mysterious',
	'Mystical', 'Relaxed', 'Somber', 'Suspenseful',
	'Unnerving', 'Uplifting', 'intense']

songs = []

def get_number_of_pages(soup):
	return int(soup.find('ul', class_='pagination').find_all('li')[-1].a.get('href').split('page=')[-1]) + 1

def download_file(url):
	file_name = url.split('/')[-1]
	file_name = file_name.replace('%20', ' ')
	u = urllib2.urlopen(url)
	f = open(file_name, 'wb')
	f.write(u.read())
	f.close()

def is_song_table(table):
	return len(table.find_all('h4', class_='\\\"musictitle\\\"')) != 0

def get_song_tables_from_soup(soup):
	all_tables = soup.find_all('table')
	song_tables = [table for table in all_tables if is_song_table(table)]
	return song_tables

def get_song_from_song_table(song_table):
	song = {}
	paragraphs = song_table.find_all('p')
	tags_paragraph = [p for p in paragraphs if len(p.find_all('i')) != 0][0]
	details_paragraph = [p for p in paragraphs if len(p.find_all('br')) != 0][-1]
	song['title'] = song_table.find('h4', class_='\\\"musictitle\\\"').text
	song['link'] = song_table.find('a', class_='btn-primary').get('href')
	song['description'] = paragraphs[0].text
	song['tags'] = tags_paragraph.i.text.split(', ')
	details = details_paragraph.text.split('\n')
	for detail in details:
		if 'Genre' in detail:
			song['genre'] = detail.split(': ')[-1]
		if 'Collection' in detail:
			song['collection'] = detail.split(': ')[-1]
		if 'Time' in detail:
			song['time'] = detail.split(': ')[-1]
		if 'Instruments' in detail:
			song['instruments'] = detail.split(': ')[1].split(',')
	return song

def song_already_exists(new_song):
	print new_song['title']
	for song in songs:
		if song['title'] == new_song['title']:
			return True
	return False

def add_songs_from_soup(soup):
	for song_table in get_song_tables_from_soup(soup):
		song = get_song_from_song_table(song_table)
		if not song_already_exists(song):
			songs.append(song)

def get_soup(keyword, page):
	url = 'http://incompetech.com/music/royalty-free/index.html?feels%5B%5D=' + keyword + '&page=' + str(page)
	print url
	return BeautifulSoup(urllib2.urlopen(url).read())



root_url = 'http://incompetech.com/music/royalty-free/index.html?feels%5B%5D=%s&page=%s'
download_root= 'http://incompetech.com'

def run():

	# Scrape text data, make list of dictionaries
	for keyword in keywords:
		soup = get_soup(keyword, 0)
		num_pages = get_number_of_pages(soup)
		for page in range(num_pages):
			soup = get_soup(keyword, page)
			add_songs_from_soup(soup)

	# Write to file as JSON
	json_string = json.dumps(songs)
	json_file = open('song_data.json', 'w')
	json_file.write(json_string)
	json_file.close()

	# Download files
	# for song in songs:
	# 	link = song['link']
	# 	file_name = link.split('/')[-1]
	# 	file_name = file_name.replace('%20', ' ')
	# 	if not os.path.isfile(file_name):
	# 		download_file(download_root + link)
	# 	print link


# html = urllib2.urlopen('http://incompetech.com/music/royalty-free/index.html?feels%5B%5D=Action&page=2').read()
# soup = BeautifulSoup(html)

run()