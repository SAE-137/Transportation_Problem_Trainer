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
};

#endif // MINCOSTSOLVER_H
