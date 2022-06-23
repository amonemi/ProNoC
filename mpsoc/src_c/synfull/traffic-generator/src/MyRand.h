/* 
Copyright (c) 2014, Mario Badr
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
/*
 * MyRand.h
 *
 *  Created on: 2013-05-15
 *      Author: badrmari
 */

#ifndef MYRAND_H_
#define MYRAND_H_

#include <memory>
#include <vector>
#include <map>
#include <random>
#include <iostream>


#define RND_ENG_NUM   4
#define DEFAULT_ENG   0
#define hierClass_ENG 1
#define INIT_MSG_ENG  2
#define REACT_ENG     3


extern std::mt19937 mt_rng [RND_ENG_NUM];

template <class T>
class DiscreteDistribution {
public:
	DiscreteDistribution() { dist = nullptr;}

	~DiscreteDistribution() {
		//delete dist;
	}

	void Add(T value) { values.push_back(value);
	//delete dist;
	dist = nullptr; }

	int Generate(int num) {
		if(values.size() == 0) {
			return -1;
		}

		create_dist();
		return (*dist)(mt_rng[num]);
	}

	void Print() {
		if(values.size() == 0) {
			return;
		}

		create_dist();

		std::vector<double> prob = dist->probabilities();
		std::vector<double>::iterator it;

		for(it = prob.begin(); it != prob.end(); it++) {
			std::cout << *it << ",";
		}
		std::cout << std::endl;
	}
private:
	std::discrete_distribution<>* dist;
	std::vector<T> values;

	void create_dist() {
		if(dist == nullptr) {
			dist = new std::discrete_distribution<>
			(values.begin(), values.end());
		}
	}
};

class ExponentialDistribution {
public:
	ExponentialDistribution(double lambda, int intervals);

	std::map<int, int> Generate(int samples);
private:
	double _lambda;
	int _intervals;
};

class BernoulliDistribution {
public:
	BernoulliDistribution(double p) {
		dist = new std::bernoulli_distribution(p);
	}

	~BernoulliDistribution() {
		//delete dist;
	}

	void SetProbability(double p) {
		//delete dist;
		dist = new std::bernoulli_distribution(p);
	}

	bool Generate(int num) {
		return (*dist)(mt_rng[num]);
	}

private:
	std::bernoulli_distribution* dist;
};

class UniformDistribution {
public:
	UniformDistribution(int min, int max) {
		dist = new std::uniform_int_distribution<int>(min, max);
	}
	~UniformDistribution() {
		//delete dist;
	}

	void SetMinMax(int min, int max) {
		//delete dist;
		dist = new std::uniform_int_distribution<int>(min, max);
	}

	int Generate(int num) {
		return (*dist)(mt_rng[num]);
	}
private:
	std::uniform_int_distribution<int>* dist;
};

#endif /* MYRAND_H_ */
