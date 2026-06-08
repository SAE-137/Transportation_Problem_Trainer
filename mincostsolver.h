#ifndef MINCOSTSOLVER_H
#define MINCOSTSOLVER_H

#pragma once

#include <QString>
#include <QVector>

#include "transportProblemState.h"

struct MinCostStep
{
    QString title;
    QString description;

    QVector<QVector<int>> costMatrix;
    QVector<int> supply;
    QVector<int> demand;

    QVector<QVector<QString>> loadMatrix;
    QVector<QVector<QString>> markMatrix;

    int selectedRow = -1;
    int selectedCol = -1;
};

struct MinCostResult
{
    bool valid = false;
    QString message;

    QVector<MinCostStep> steps;
    QVector<QVector<QString>> finalLoadMatrix;
};

class MinCostSolver
{
public:
    MinCostResult solve(const TransportProblemState& source) const;

private:
    bool hasOpenCells(const QVector<int>& supply, const QVector<int>& demand) const;
    QVector<QVector<QString>> makeStringMatrix(int rows, int cols) const;

    bool isBasisCell(const QVector<QVector<QString>>& loadMatrix, int row, int col) const;
    int countBasisCells(const QVector<QVector<QString>>& loadMatrix) const;
    bool createsCycle(const QVector<QVector<QString>>& loadMatrix, int addRow, int addCol) const;

    bool chooseZeroBasisCell(const QVector<QVector<QString>>& loadMatrix,
                             const QVector<int>& supplyLeft,
                             const QVector<int>& demandLeft,
                             int chosenRow,
                             int chosenCol,
                             int& zeroRow,
                             int& zeroCol) const;
};

#endif // MINCOSTSOLVER_H
