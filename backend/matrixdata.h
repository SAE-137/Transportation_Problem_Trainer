#ifndef MATRIXDATA_H
#define MATRIXDATA_H

#include<QVector>

struct Cell {
    int cost = 0;
    int cargo = 0;
    bool isBasic = false;
    bool isForbidden = false;
};


class MatrixData {
public:
    int rows;
    int cols;
    QVector<QVector<Cell>> table;
};


#endif // MATRIXDATA_H
